defmodule GhTrends do
  @moduledoc """
  Main utility functions that are used to start different parts of the
  application.
  """
  require Logger, as: L


  @doc """
  Fetches repositories that have more that 100 stars, with descending order
  on stars.
  """
  def fetch_trending do
    case Github.trending("stars:>100", [sort: :stars, order: :desc]) do
      %{status: 200, body: b} ->
        repos = Map.fetch!(b, "items")
        L.info("Fetched #{Enum.count(repos)}")
        repos
      resp ->
        L.error("Failed to fetch trending with: #{inspect resp}")
        []
    end
  end

  @doc """
  Fetches trending repositories and stores them into db.
  """
  def process_trending do
    case fetch_trending() |> GhTrends.Db.write_raw_repos() do
      {:atomic, rs} ->
        noks = Enum.filter(rs, &(:ok != &1))
        noks_c = Enum.count(noks)
        oks = Enum.count(rs) - noks_c
        L.info("Saved repos, ok/nok: #{oks}/#{noks_c}")
        {:errors, noks}
      err ->
        L.error("Failed to save trandings: #{inspect err}")
        err
    end
  end

  @doc """
  Starts timer that will `process_trending/0` each `ms` ms. If
  `opts[:force] == true` it will reset timer to the new time even if it already
  started.
  """
  def start_sync(ms, opts \\ []) when is_integer(ms) do
    opts = Keyword.merge([force: false], opts)
    mfa  = [GhTrends, :process_trending, []]
    case {Timer.start_repeat_task(ms, mfa, GhTrends), opts[:force]} do
      {{:ok, _}, _} ->
        :ok
      {{:error, :already_started}, true} ->
        stop_sync()
        start_sync(ms, [])
      {err = {:error, :already_started}, false} ->
        err
      {err, _} ->
        L.error("Failed to start sync: #{inspect err}")
        err
    end
  end

  @doc """
  Stops trending repos fetching timer
  """
  def stop_sync do
    Timer.stop_task(GhTrends)
  end

  @doc """
  Restarts trending repos fetching timer
  """
  def restart_sync do
    Timer.restart_task(GhTrends)
  end

end
