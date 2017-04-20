defmodule Timer.Task.Repeat do
  @moduledoc """
  Task that will try to launch code with specified interval
  """
  use GenServer
  require Logger, as: L

  defmodule S do
    @enforce_keys [:id, :task, :int, :timer, :state]
    defstruct [:id, :task, :int, :timer, :task_pid, :state]
  end

  def start_link(id, task, interval) do
    GenServer.start_link(__MODULE__, {id, task, interval})
  end

  def start(id, task, interval) do
    GenServer.start(__MODULE__, {id, task, interval})
  end

  @doc """
  Initializes task.

  ## Params
  `id` - uniq name that is used by supervisor to identify this process
  `task` - `[function]` or `[m,f,a]`
  `int` - interval in ms

  It will launch `task` each `int` in separate thread linked to this process.
  `:trap_exit` is used to monitor running task.
  """
  def init({id, task, int}) do
    Process.flag(:trap_exit, true)
    L.info("Starting rep task handler #{id} with interval #{int}")
    {:ok, timer} = :timer.send_interval(int, :run)
    {:ok, %S{ id: id, task: task, int: int, timer: timer, state: :waiting}}
  end

  # Tried to launch task when it's already running
  def handle_info(:run, st = %S{state: :running}) do
    L.warn("Rep task #{st.id} is already running")
    {:noreply, st}
  end

  # Launching task normally
  def handle_info(:run, st = %S{state: :waiting}) do
    p = apply(Kernel, :spawn_link, st.task)
    {:noreply, %{st | task_pid: p, state: :running}}
  end

  # Task finished with whatever reason, fixing state
  def handle_info({:EXIT, pid, _reason}, st = %S{ task_pid: pid}) do
    {:noreply, %{st | task_pid: nil, state: :waiting}}
  end

  def handle_info(msg, st) do
    L.warn("Unknown message for rep handler #{st.id}: #{inspect msg}")
    {:noreply, st}
  end

  # Cleaning up by removing timer, linked task will die on its own
  def terminate(reason, st) do
    L.info("Terminating rep task handler #{st.id}: #{inspect reason}")
    :timer.cancel(st.timer)
    :ok
  end

end
