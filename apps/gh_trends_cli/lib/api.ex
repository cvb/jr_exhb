defmodule Api do
  @moduledoc """
  HTTP client for `GhTrends`
  """
  use Tesla

  def repo(client, name, verbose \\ false) do
    get(client, "/repo/" <> name, query: [verbose: verbose])
  end

  def repos(client, verbose \\ false) do
    get(client, "/repos", query: [verbose: verbose])
  end

  def start_sync(client, ms, force \\ false) do
    post(client, "/start_sync/#{ms}", "", query: [force: force])
  end

  def stop_sync(client) do
    post(client, "/stop_sync", "")
  end


  def client(base) do
    Tesla.build_client [
      {Tesla.Middleware.BaseUrl, base}
    ]
  end

end
