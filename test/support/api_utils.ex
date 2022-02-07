defmodule Skynet.ApiUtils do
  @moduledoc """
  This module defines common utilities for HTTP Api tests.
  """
  import Plug.Test
  alias Skynet.Api

  def make_request(method, url, payload \\ nil) do
    method
    |> conn(url, payload)
    |> Api.call([])
  end
end
