defmodule Timer.Registry do
  @moduledoc """
  Main interface module for timers.
  Provides API to start, stop, restart and show tasks. Each task is a separate
  process, supervised by `Timer.Task.Supervisor` with `:one_for_one` strategy,
  So even when task dies trying to fulfill its duty, it will be relaunched.

  Also `Timer.Task.Supervisor` is used as a catalog of running tasks, each
  task have unique id.

  Task receives code that it should run during its start with functions like
  `start_repeat_task/3`. It's responsibility of the task to determine how it
  will launch it's code and who will monitor it.

  Currently only repeating tasks are implemented. This type of task will
  try to launch code with specified interval. Code will be launched in
  dedicated process and monitored by the task.
  If code is still running when it's time to launch it again it will not be
  launched.
  """
  use GenServer
  alias GenServer, as: G

  @doc """
  Starts registry.

  ## Params
  `sup` - supervisor, that will supervise this registry and that will
  launch `Timer.Task.Supervisor`
  `opts` - not used yet

  """
  def start_link(sup, opts \\ []) do
    G.start_link(__MODULE__, sup, opts)
  end

  @doc """
  Starts repeating task

  ## Params
  `pid` - pid or name of the running `Timer.Registry` process
  `interval` - repeat interval in ms
  `task` - function of `[module, function, args]` as for `apply`
  `name` - optional name, if omitted `:erlang.make_ref/0` will be used

  ## Return
  `{:ok, name}` - when success
  `{:error, reason}` - when failed
  """
  def start_repeat_task(pid, interval, task, name \\ :erlang.make_ref)

  def start_repeat_task(pid, interval, f, name)
  when is_function(f)
   and is_integer(interval)
   and interval > 0
  do
    G.call(pid, {:start_repeat, interval, [f], name})
  end

  def start_repeat_task(pid, interval, mfa = [m, f, a], name)
  when is_atom(m)
   and is_atom(f)
   and is_list(a)
   and is_integer(interval)
   and interval > 0
  do
    G.call(pid, {:start_repeat, interval, mfa, name})
  end

  def stop_task(pid, name) do
    G.call(pid, {:stop_task, name})
  end

  def restart_task(pid, name) do
    G.call(pid, {:restart_task, name})
  end

  def tasks(pid) do
    G.call(pid, :tasks)
  end

  @doc """
  Initialize registry.
  As a first thing it will try to start `Timer.Task.Supervisor`, it's
  supervised bu `Timer.Task` but this way we will get it's pid to control
  other tasks later.
  """
  def init(sup) do
    send self(), {:start_task_supervisor, sup}
    {:ok, {}}
  end

  def handle_info({:start_task_supervisor, sup}, _) do
    {:ok, pid} = Timer.Supervisor.start_task_sup(sup)
    {:noreply, pid}
  end

  def handle_call({:start_repeat, interval, task, name}, _from, sup) do
    case Timer.Task.Supervisor.start_repeat(sup, name, task, interval) do
      {:ok, _pid}        -> {:reply, {:ok, name}, sup}
      {:ok, _pid, _info} -> {:reply, {:ok, name}, sup}

      {:error, {:already_started, _pid}} ->
        {:reply, {:error, :already_started}, sup}
      {:error, :already_present} ->
        {:reply, {:error, :already_started}, sup}
      {:error, reason} ->
        IO.warn("Failed to start task with reason #{inspect reason}")
        {:reply, {:error, reason}, sup}
    end
  end

  def handle_call({:stop_task, name}, _from, sup) do
    {:reply, Timer.Task.Supervisor.stop_task(sup, name), sup}
  end

  def handle_call({:restart_task, name}, _from, sup) do
    {:reply, Timer.Task.Supervisor.restart_task(sup, name), sup}
  end

  def handle_call(:tasks, _from, sup) do
    {:reply, Supervisor.which_children(sup), sup}
  end

end
