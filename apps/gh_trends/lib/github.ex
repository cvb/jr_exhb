defmodule Github do
  @moduledoc """
  Tools to talk to github API.
  """
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.github.com"
  plug Tesla.Middleware.Headers,
    %{ "User-Agent" => "ibrowse",
       "Accept" => "application/vnd.github.v3+json",
    }
  plug Tesla.Middleware.JSON

  def trending(q, opts \\ []) do
    get "/search/repositories", query: (opts ++ [q: q])
  end

end
