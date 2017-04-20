defmodule GhTrendsCli do
  @moduledoc """
  Main module of the CLI app for `GhTrends` HTTP API.
  This module mostly do arguments processing, delegating HTTP coomunications
  to `Api`.
  """

  def main(args) do
    opts =
      [switches: [verbose: :boolean,
                  name:    :string,
                  ms:      :integer,
                  host:    :string,
                  force:   :boolean
                 ],
       aliases:  [v: :verbose,
                  n: :name,
                  m: :ms,
                  h: :host,
                  f: :force,
                 ],
      ]
    {opts,o,_}= OptionParser.parse(args, opts)

    case o do
      ["repo"] ->
        handle_repo(opts)
      ["repos"] ->
        handle_repos(opts)
      ["start_sync"] ->
        handle_start_sync(opts)
      ["stop_sync"] ->
        handle_stop_sync(opts)
      _ ->
        die("Unknown command, supported: repo, repos, start_sync, and stop_sync")
    end
  end

  @default_host "http://localhost:4001"

  def handle_repo(opts) do
    case opts[:name] do
      nil ->
        die("--name option is required for repo command")
      v ->
        print_resp(Api.repo(client(opts), v, opts[:verbose] || false))
    end
  end

  def handle_repos(opts) do
    print_resp(Api.repos(client(opts), opts[:verbose] || false))
  end

  def handle_start_sync(opts) do
    case opts[:ms] do
      nil ->
        die("--ms option is required for start_sync command")
      v ->
        print_resp(Api.start_sync(client(opts), v, opts[:force] || false))
    end
  end

  def handle_stop_sync(opts) do
    print_resp(Api.stop_sync(client(opts)))
  end

  def client(opts) do
    Api.client(opts[:host] || @default_host)
  end

  def die(str, code \\ 1) do
    IO.puts(:stderr, str)
    System.halt(code)
  end

  def print_resp(resp = %{status: 200}) do
    IO.puts(resp.body)
  end

  def print_resp(resp= %{status: s}) do
    IO.puts(:stderr, "Failed, response code: #{s}")
    die(resp.body)
  end

end
