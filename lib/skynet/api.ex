defmodule Skynet.Api do
  @moduledoc """
  Skynet Rest API to manage Terminators.
  """
  require Logger

  use Plug.Router
  use Plug.ErrorHandler

  alias Plug.Conn.Status
  alias Skynet.Terminators

  plug Plug.RequestId
  plug Plug.Logger
  plug :match
  plug Plug.Telemetry, event_prefix: [:skynet, :plug]
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch, builder_opts()

  get "/_health" do
    version = Application.spec(:skynet, :vsn)

    json_resp(conn, 200, %{version: List.to_string(version)})
  end

  post "/terminators" do
    name = Access.get(conn.params, "name")

    {:ok, result} = Terminators.create(name)
    json_resp(conn, 201, %{data: result})
  end

  get "/terminators" do
    json_resp(conn, 200, %{data: Terminators.list()})
  end

  delete "/terminators/:name" do
    name = Access.get(conn.path_params, "name")

    case Terminators.kill(name) do
      :ok ->
        json_resp(conn, 204, "")

      {:error, :not_found} ->
        json_resp(conn, 404)
    end
  end

  match _ do
    json_resp(conn, 404)
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
    formatted_reason = Exception.format(kind, reason)
    formatted_stack = Exception.format_stacktrace(stack)

    Logger.error(
      "Unexpected error handling API call" <>
        " method=#{conn.method}, path=#{conn.request_path}",
      kind: kind,
      reason: formatted_reason,
      stacktrace: formatted_stack
    )

    response = %{errors: [Status.reason_phrase(conn.status)]}
    json_resp(conn, conn.status, response)
  end

  defp json_resp(conn, status) when status in [404, :not_found] do
    body = %{errors: [Status.reason_phrase(404)]}
    json_resp(conn, status, body)
  end

  defp json_resp(conn, status, body \\ "") do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
    |> halt()
  end
end
