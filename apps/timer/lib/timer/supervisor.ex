defmodule Timer.Supervisor do
  @moduledoc """
  Supervises `Timer.Task.Supervisor` and `Timer.Registry`.

  Strategy `:rest_for_one` is significant, this way `Timer.Registry` will
  always have correct `pid` of the task's supervisor.
  """
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def start_task_sup(pid) do
    resp =
      Supervisor.start_child(
        pid,
        supervisor(Timer.Task.Supervisor, [])
      )
    case resp do
      ok = {:ok, _pid} ->
        ok
      {:error, {:already_started, pid}} ->
        {:ok, pid}
      v ->
        v
    end
  end

  def init(opts) do
    children = [
      supervisor(Timer.Task.Supervisor, []),
      worker(Timer.Registry, [self(), opts],
        restart: :permanent,
        id:      Timer.Registry)
    ]

    supervise(children, strategy: :rest_for_one)
  end

end
