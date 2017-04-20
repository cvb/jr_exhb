defmodule Timer.Task.Supervisor do
  @moduledoc """
  Supervisor, dedicated to monitor tasks only.
  """
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def start_repeat(sup, name, task, int) do
    Supervisor.start_child(
      sup,
      worker(Timer.Task.Repeat, [name, task, int], [id: name]))
  end

  def stop_task(sup, name) do
    case Supervisor.terminate_child(sup, name) do
      :ok ->
        :ok = Supervisor.delete_child(sup, name)
        :ok
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  def restart_task(sup, name) do
    case Supervisor.terminate_child(sup, name) do
      :ok ->
        {:ok, _pid} = Supervisor.restart_child(sup, name)
        :ok
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  def init(:ok) do
    supervise([], strategy: :one_for_one)
  end

end
