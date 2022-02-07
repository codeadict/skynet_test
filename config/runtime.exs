import Config

config :skynet, Skynet.Api, port: System.get_env("SKYNET_PORT", "4000") |> String.to_integer()

config :logger, level: System.get_env("SKYNET_LOG_LEVEL", "info") |> String.to_existing_atom()
