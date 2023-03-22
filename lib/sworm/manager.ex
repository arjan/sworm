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

  def set_suspended(sworm, flag) do
    GenServer.call(manager_name(sworm), {:set_suspended, flag})
  end

  ###

  require Logger

  defmodule State do
    @moduledoc false
    defstruct sworm: nil, nodes: [], opts: [], suspended: false
  end

  if Mix.env() == :test do
    @check_interval 10
  else
    @check_interval 1000
  end

  def init({sworm, opts}) do
    state = %State{sworm: sworm, opts: opts}

    :timer.send_interval(@check_interval, :check)
    Sworm.DirectoryManager.set_node_state(state.sworm, node_state(state))

    {:ok, state}
  end

  def handle_call({:set_suspended, flag}, _from, state) do
    state = %{state | suspended: flag}
    Sworm.DirectoryManager.set_node_state(state.sworm, node_state(state))
    {:reply, :ok, state}
  end

  def handle_info(:check, state) do
    Sworm.DirectoryManager.set_node_state(state.sworm, node_state(state))
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

        old_nodes = state.nodes -- nodes

        if node() in old_nodes do
          # terminate lingering delegates that are on a node that is now going away

          match = [{{{:delegate, :"$1"}, :"$2", :"$3"}, [], [:"$3"]}]

          Horde.Registry.select(registry_name(state.sworm), match)
          |> Enum.uniq()
          |> Enum.filter(&(node(&1) == node()))
          |> IO.inspect(label: "terminating")
          |> Enum.each(&Process.exit(&1, {:shutdown, :process_redistribution}))
        end

        %State{state | nodes: nodes}
    end
  end

  defp node_state(%{suspended: false}), do: :alive
  defp node_state(%{suspended: true}), do: :suspended
end
