defmodule Skynet.Terminators do
  @moduledoc """
  Manages Terminators in the system.
  """
  require Logger

  alias Skynet.Terminator.Server

  @registry Skynet.TerminatorRegistry
  @supervisor Skynet.TerminatorSupervisor

  @doc """
  Spawns a new Terminator
  """
  @spec create(String.t() | nil) ::
          {:ok, %{optional(:name) => String.t(), optional(:pid) => String.t()}} | {:error, any}
  def create(name \\ nil) do
    case Server.create(name) do
      {:ok, pid} ->
        wrap_created(pid)

      {:ok, pid, _info} ->
        wrap_created(pid)

      {:error, {:already_started, pid}} ->
        wrap_created(pid)

      other ->
        Logger.error("unable to create terminator", reason: inspect(other))
        {:error, :not_created}
    end
  end

  @doc """
  Lists all the alive Terminators
  """
  @spec list :: [%{:name => String.t()}, ...]
  def list do
    @registry
    |> Registry.select([{{:"$1", :"$2", :"$3"}, [], [{{:"$1"}}]}])
    |> Enum.map(fn {name} -> %{name: name} end)
  end

  @doc """
  Kills a Terminator by it's name
  """
  @spec kill(String.t()) :: :ok | {:error, :not_found}
  def kill(name) do
    with [{pid, nil}] <- Registry.lookup(@registry, name),
         :ok <- DynamicSupervisor.terminate_child(@supervisor, pid) do
      :ok
    else
      [] -> {:error, :not_found}
      error -> error
    end
  end

  defp wrap_created(pid) do
    result =
      @registry
      |> Registry.select([{{:"$1", :"$2", :"$3"}, [{:==, :"$2", pid}], [{{:"$1", :"$2"}}]}])
      |> Enum.map(fn {name, pid} -> %{name: name, pid: inspect(pid)} end)
      |> hd()

    {:ok, result}
  end
end
