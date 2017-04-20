defmodule GhTrends.WebUi do
  @moduledoc """
  HTTP API to cotrol timer and retrieve stored repositories. It also serves
  static files for react app.
  """
  use Plug.Router
  require Logger, as: L

  plug Plug.Logger

  plug Plug.Static,
    at: "/",
    from: :gh_trends

  plug :match
  plug :dispatch

  get "/repo/:id_or_name" do

    resp =
      case Integer.parse(id_or_name) do
        {id, ""} -> GhTrends.Db.find_repo(id: id, name: id_or_name)
        _        -> GhTrends.Db.repo_by_name(id_or_name)
      end

    case resp do
      {:atomic, [r]} ->
        resp = GhTrends.Db.repo_to_map(r, verbose: verbose?(conn))
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Poison.encode!(resp, pretty: true))
      _ ->
        send_resp(conn, 404, "")
    end
  end

  get "/repos" do
    case GhTrends.Db.all_repos do
      {:atomic, r} ->
        repos =
          r
          |> GhTrends.Db.repos_to_map(verbose: verbose?(conn))
          |> Enum.sort_by(&(&1[:stars]))
        send_resp(conn, 200, Poison.encode!(repos, pretty: true))
    end
  end

  post "/start_sync/:ms" do
    bad_ms_err = Poison.encode!(%{error: "ms should be positive integer"})
    case Integer.parse(ms) do
      {ms, ""} when ms > 0 ->
        case GhTrends.start_sync(ms, [force: force?(conn)]) do
          :ok ->
            send_resp(conn, 200, Poison.encode!(%{ok: :started}))
          {:error, :already_started} ->
            send_resp(conn, 200, Poison.encode!(%{error: :already_started}))
          err ->
            L.error("Failed to start sync with #{inspect err}")
            send_resp(conn, 500, "")
        end
      {ms, ""} ->
        send_resp(conn, 400, bad_ms_err)
      _ ->
        send_resp(conn, 400, bad_ms_err)
    end
  end

  post "/stop_sync" do
    case GhTrends.stop_sync() do
      :ok ->
        send_resp(conn, 200, Poison.encode!(%{ok: :stopped}))
      {:error, :not_found} ->
        send_resp(conn, 200, Poison.encode!(%{error: :not_running}))
    end
  end



  match _ do
    send_resp(conn, 404, "oops")
  end

  defp force?(conn) do
    case fetch_query_params(conn, []).params do
      %{"force" => "true"} -> true
      _                    -> false
    end
  end

  defp verbose?(conn) do
    case fetch_query_params(conn, []).params do
      %{"verbose" => "true"} -> true
      _                      -> false
    end
  end

end
