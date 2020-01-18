defmodule Sworm.Manager do
  @moduledoc false

  use GenServer

  import Sworm.Util

  def child_spec({sworm, opts}) do
    %{
      id: manager_name(sworm),
      start: {__MODULE__, :start_link, [{sworm, opts}]},
      restart: :transient
    }
  end

  def start_link({sworm, opts}) do
    GenServer.start_link(__MODULE__, {sworm, opts}, name: manager_name(sworm))
  end

  ###

  require Logger

  defmodule State do
    @moduledoc false
    defstruct sworm: nil, nodes: [], opts: []
  end

  def init({sworm, opts}) do
    :timer.send_interval(1000, :check)
    {:ok, %State{sworm: sworm, opts: opts}}
  end

  def handle_info(:check, state) do
    Sworm.DirectoryManager.register(state.sworm)
    {:noreply, update_nodes(state)}
  end

  def update_nodes(state) do
    nodes = Sworm.DirectoryManager.nodes_for_sworm(state.sworm)

    case nodes == state.nodes do
      true ->
        state

      false ->
        Logger.debug("[#{state.sworm}] Node list updated to #{inspect(nodes)}")

        for mod <- [supervisor_name(state.sworm), registry_name(state.sworm)] do
          Horde.Cluster.set_members(mod, Enum.map(nodes, fn node -> {mod, node} end))
        end

        %State{state | nodes: nodes}
    end
  end
end
