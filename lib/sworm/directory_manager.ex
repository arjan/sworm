defmodule Sworm.DirectoryManager do
  @moduledoc false

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def nodes_for_sworm(sworm) do
    match = [{{{sworm, :"$1"}, :"$2", :"$3"}, [], [:"$1"]}]

    Horde.Registry.select(Sworm.Directory, match)
    |> Enum.filter(fn n -> :pong == Node.ping(n) end)
    |> Enum.sort()
  end

  ###

  require Logger

  def init([]) do
    :net_kernel.monitor_nodes(true, [])
    {:ok, update_nodes([])}
  end

  def handle_info({node_event, _node}, state)
      when node_event == :nodeup or node_event == :nodedown do
    {:noreply, update_nodes(state)}
  end

  def handle_info(_request, state) do
    {:noreply, state}
  end

  def update_nodes(state) do
    nodes = Enum.sort([Node.self() | Node.list()])

    case nodes == state do
      true ->
        state

      false ->
        Logger.info("Node directory list updated to #{inspect(nodes)}")
        Horde.Cluster.set_members(Sworm.Directory, Enum.map(nodes, &{Sworm.Directory, &1}))
        nodes
    end
  end
end
