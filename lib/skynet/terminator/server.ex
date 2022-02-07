defmodule Skynet.Terminator.Server do
  @moduledoc """
  This process represents a single Terminator in the system
  """
  use GenServer, restart: :transient

  require Logger

  @supervisor Skynet.TerminatorSupervisor

  defmodule State do
    @moduledoc false
    defstruct name: nil,
              reproduction_period: :timer.seconds(5),
              reproduction_odds: 20,
              elimination_period: :timer.seconds(10),
              elimination_odds: 25

    @type t() :: %{
            name: String.t(),
            reproduction_period: non_neg_integer(),
            reproduction_odds: number(),
            elimination_period: non_neg_integer(),
            elimination_odds: number()
          }
  end

  @spec create(any) :: :ignore | {:error, any} | {:ok, pid} | {:ok, pid, any}
  def create(name) do
    DynamicSupervisor.start_child(@supervisor, {__MODULE__, [name: name]})
  end

  def start_link(opts) do
    name = opts[:name] || random_name()
    state = struct(State, Keyword.put(opts, :name, name))

    GenServer.start_link(__MODULE__, state, name: via(name))
  end

  @impl true
  def init(%State{name: name} = state) do
    :crypto.rand_seed()
    Logger.metadata(terminator_name: name)
    Logger.debug("a new terminator has been sent to destroy humanity")
    schedule_next_reproduction(state.reproduction_period)
    schedule_sarah_encounter(state.elimination_period)
    {:ok, state}
  end

  @impl true
  def handle_info(
        :maybe_reproduce,
        %State{reproduction_odds: reproduction_odds, reproduction_period: reproduction_period} =
          state
      ) do
    if has_odds?(reproduction_odds) do
      Logger.debug("reproducing a new terminator")
      create(random_name())
    end

    schedule_next_reproduction(reproduction_period)
    {:noreply, state}
  end

  @impl true
  def handle_info(
        :encounter_with_sarah,
        %State{elimination_odds: elimination_odds, elimination_period: elimination_period} = state
      ) do
    if has_odds?(elimination_odds) do
      Logger.debug("killed by Sarah Connor")
      Process.exit(self(), :normal)
    end

    schedule_sarah_encounter(elimination_period)
    {:noreply, state}
  end

  defp schedule_next_reproduction(reproduction_period) do
    Process.send_after(self(), :maybe_reproduce, reproduction_period)
  end

  defp schedule_sarah_encounter(elimination_period) do
    Process.send_after(self(), :encounter_with_sarah, elimination_period)
  end

  defp has_odds?(probability), do: Enum.random(0..100) >= probability

  defp via(name), do: {:via, Registry, {Skynet.TerminatorRegistry, name}}

  defp random_name do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
