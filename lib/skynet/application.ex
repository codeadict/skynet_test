defmodule Skynet.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @impl Application
  def start(_type, _args) do
    children = [
      {Registry,
       keys: :unique, name: Skynet.TerminatorRegistry, partitions: System.schedulers_online()},
      {DynamicSupervisor, name: Skynet.TerminatorSupervisor, strategy: :one_for_one},
      {Plug.Cowboy, scheme: :http, plug: Skynet.Api, options: [port: api_port()]}
    ]

    Logger.info("Starting Skynet API on #{api_port()}...")
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Skynet.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp api_port do
    :skynet
    |> Application.get_env(Skynet.Api)
    |> Keyword.get(:port)
  end
end
