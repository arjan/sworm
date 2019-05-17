defmodule Sworm.Manager do
  @moduledoc false

  use GenServer

  import Sworm.Util

  def child_spec({sworm, _opts}) do
    %{
      id: manager_name(sworm),
      start: {__MODULE__, :start_link, [sworm]},
      restart: :transient
    }
  end

  def start_link(sworm) do
    GenServer.start_link(__MODULE__, sworm, name: manager_name(sworm))
  end

  ###

  require Logger

  defmodule State do
    defstruct sworm: nil, nodes: [], receivers: []
  end

  def init(sworm) do
    :net_kernel.monitor_nodes(true, [])
    Process.flag(:trap_exit, true)
    {:ok, %State{sworm: sworm, nodes: update_nodes(sworm)}}
  end

  def handle_info({:EXIT, _pid, reason}, state) do
    {:stop, reason, state}
  end

  def handle_info({node_event, _node}, state)
      when node_event == :nodeup or node_event == :nodedown do
    nodes = update_nodes(state.sworm)
    {:noreply, %State{state | nodes: nodes}}
  end

  def handle_info(request, state) do
    {:noreply, state}
  end

  def terminate(reason, _state) do
    :ok
  end

  def update_nodes(sworm) do
    nodes = Enum.sort([Node.self() | Node.list()])
    Logger.debug("**** Node list updated to #{inspect(nodes)}")

    for mod <- [supervisor_name(sworm), registry_name(sworm)] do
      Horde.Cluster.set_members(mod, Enum.map(nodes, fn node -> {mod, node} end))
    end

    nodes
  end
end
