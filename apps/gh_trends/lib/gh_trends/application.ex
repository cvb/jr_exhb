defmodule GhTrends.Application do
  @moduledoc """
  GhTrends app initialization.

  This app can be configured with env variables, see describtion below for
  details.

  ## Evn vars
  - GH_TRENDS_PORT - port for HTTP API, default @default_port
  - GH_TRENDS_START_SYNC - if true, github sync will be launched with app init,
    default is false
  - GH_TRENDS_SYNC_INTERVAL - interval in ms of github sync, default is 10000
  - MNESIA_DIR - directory for mnesia, default is not set, si it will use
    current dir
  """

  @default_port  4001
  @start_sync    false
  @sync_interval 10000

  use Application
  require Logger, as: L

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    my_custom_config()

    L.info("Starting app #{__MODULE__}")

    L.info("Initiating db")
    GhTrends.Db.init_db()

    if Application.get_env(:gh_trends, :start_sync, @start_sync) do
      L.info("Starting sync")
      GhTrends.start_sync(
        Application.get_env(:gh_trends, :sync_interval, @sync_interval))
    end

    # Define workers and child supervisors to be supervised
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, GhTrends.WebUi, [],
        [port: Application.get_env(:gh_trends, :port, @default_port)])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GhTrends.Supervisor]
    r = Supervisor.start_link(children, opts)

    L.info("#{__MODULE__} started")

    r
  end

  def my_custom_config do
    case Integer.parse(System.get_env("GH_TRENDS_PORT") || "") do
      {v, ""} -> :application.set_env(:gh_trends, :port, v)
      _       -> nil
    end

    start_sync =
      case System.get_env("GH_TRENDS_START_SYNC")  do
        "true" -> true
        _      -> false
      end
    :application.set_env(:gh_trends, :start_sync, start_sync)

    case Integer.parse(System.get_env("GH_TRENDS_SYNC_INTERVAL") || "")  do
      {v, ""} ->
        :application.set_env(:gh_trends, :sync_interval, v)
      _       ->
        nil
    end

    mnesia_dir = System.get_env("MNESIA_DIR")
    if mnesia_dir do
      :application.set_env(:mnesia, :dir, to_charlist(mnesia_dir))
    end

  end

end
