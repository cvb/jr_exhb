defmodule GhTrends.Db do
  @moduledoc """
  Functions to initialize and query database with trending repos.
  """

  @repo_attributes [:id,
                    :name,
                    :url,
                    :stars,
                    :rest,
                   ]

  @doc """
  Initialize and launch mnesia database

  Mnesia is started from here instead of mix file because otherwise it won't
  read environment variables at runtime and that will not allow to configure
  mnesia dir with them. And if mnesia app is launched without dir it will
  use `ram_copies` for schema, which will not allow to make tables with
  `disc_copies`.
  """
  def init_db do
    case :mnesia.create_schema([node()]) do
      :ok ->
        :ok
      {:error, {_, {:already_exists, _}}} ->
        :ok
    end

    Application.start(:mnesia)

    init_gh_table()
  end

  @doc """
  Initializes table for github trending repos
  """
  def init_gh_table do
    res = :mnesia.create_table(Repo,
      [attributes: @repo_attributes,
       index: [:name],
       disc_copies: [node()]
      ])

    case res do
      {:atomic, :ok} ->
        {:atomic, :ok}
      {:aborted, {:already_exists, Repo}} ->
        {:atomic, :ok}
    end
  end

  @doc """
  Finds stored github repository by `id`.
  ## Params
  `id` - should be integer

  ## Return
  `{:atomic, []}` - when not found
  `{:atomic, [result]}` - when found
  `transaction abort` - when something went wrong see `:mnesia` doc for details
  """
  def repo_by_id(id) do
    :mnesia.transaction(fn -> :mnesia.read(Repo, id) end)
  end

  @doc """
  Finds stored github repository by `name`.
  ## Params
  `name` - should be string

  ## Return
  `{:atomic, []}` - when not found
  `{:atomic, [result]}` - when found
  `transaction abort` - when something went wrong see `:mnesia` doc for details
  """
  def repo_by_name(name) do
    :mnesia.transaction(fn -> :mnesia.index_read(Repo, name, :name) end)
  end

  @doc """
  Finds stored github repository by `id` of `name`, `id` have higher
  precedence.
  ## Params
  `opts` is a keyword list, it should contain `:id` or `:name` keys, or both

  ## Return
  `{:atomic, []}` - when not found
  `{:atomic, [result]}` - when found
  `transaction abort` - when something went wrong see `:mnesia` doc for details
  """
  def find_repo(opts) do
    case {Keyword.fetch(opts, :id), Keyword.fetch(opts, :name)} do
      {{:ok, id}, {:ok, name}} ->
        case repo_by_id(id) do
          r = {:atomic, _} -> r
          _                -> repo_by_name(name)
        end
      {{:ok, id}, _} ->
        repo_by_id(id)
      {_, {:ok, name}} ->
        repo_by_name(name)
    end
  end

  @doc """
  Finds all repos stored in mnesia.

  ## Return
  `{:atomic, [result]}`
  `transaction abort`
  """
  def all_repos do
    :mnesia.transaction fn ->
      :mnesia.foldl(fn(r, acc) -> [r | acc] end, [], Repo)
    end
  end

  @doc """
  Deletes all repos stored in mnesia.

  ## Return
  `{:atomic, :ok}`
  `{:aborted, reason}`
  """
  def clear_repos do
    :mnesia.clear_table(Repo)
  end

  @doc """
  Writes repos, decoded from json (with string keys) to thr mnesia.
  ## Return
  `{:atomic, [:ok | transaction abort]}`
  """
  def write_raw_repos(rs) when is_list(rs) do
    repos= Enum.map(rs, &to_repo/1)
    :mnesia.transaction(fn -> Enum.map(repos, &:mnesia.write/1) end)
  end

  @doc """
  Transform decoded from json list of github repos into tuple that could
  be store in mnesia repos table.
  """
  def to_repo(m) when is_map(m) do
    case m do
      %{"id"               => id,
        "name"             => name,
        "html_url"         => url,
        "stargazers_count" => stars,
      } ->
        {Repo, id, name, url, stars, m}
    end
  end

  @doc """
  Same as `repo_to_map/2` but for list
  """
  def repos_to_map(rs, opts \\ []) do
    rs |> Enum.map(&(repo_to_map &1, opts))
  end

  @doc """
  Transforms mnesia tuple into map where keys will be attributes, table name
  will have key `:type`.
  If `opts[:verbose] == true` `:rest` field with raw repository info will not
  be deleted.
  """
  def repo_to_map(r, opts \\ []) do
    map =
      Enum.zip([:type | @repo_attributes], Tuple.to_list(r))
      |> Enum.into(%{})
    case opts[:verbose] do
      true  -> map
      _     -> map |> Map.delete(:rest)
    end
  end

end
