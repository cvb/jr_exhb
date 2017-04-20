defmodule Timer do
  @moduledoc """
  Provides `Application` interface for the `Timer.Registry`.

  Basically proxying function calls to the `Timer.Registry` specifying
  first argument to the name `Timer`.
  """

  use Application
  alias Timer.Registry, as: R

  def start(_type, _args) do
    Timer.Supervisor.start_link([name: Timer])
  end

  @doc """
  Start repeating task
  For details see `Timer.Registry.start_repeat_task/3`,
  this function will specify it's first argument to `Timer`
  """
  def start_repeat_task(interval, task, name) do
    R.start_repeat_task(Timer, interval, task, name)
  end

  def start_repeat_task(interval, task) do
    R.start_repeat_task(Timer, interval, task)
  end

  @doc """
  Stop task
  For details see `Timer.Registry.stop_task/2`,
  this function will specify it's first argument to `Timer`
  """
  def stop_task(name),    do: R.stop_task(Timer, name)

  @doc """
  Restart task
  For details see `Timer.Registry.restart_task/2`,
  this function will specify it's first argument to `Timer`
  """
  def restart_task(name), do: R.restart_task(Timer, name)

  @doc """
  Return all tasks
  For details see `Timer.Registry.tasks/2`,
  this function will specify it's first argument to `Timer`
  """
  def tasks,              do: R.tasks(Timer)

end
