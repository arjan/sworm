defmodule Sworm.Manager do
  @moduledoc false

  use GenServer

  import Sworm.Util
  alias Sworm.RingUtils

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
    defstruct sworm: nil, nodes: [], opts: []
  end

  def init({sworm, opts}) do
    :net_kernel.monitor_nodes(true, [])
    state = %State{sworm: sworm, opts: opts}
    {:ok, update_nodes(state)}
  end

  def handle_info({node_event, _node}, state)
      when node_event == :nodeup or node_event == :nodedown do
    {:noreply, update_nodes(state)}
  end

  def handle_info(request, state) do
    {:noreply, state}
  end

  def terminate(reason, _state) do
    :ok
  end

  def update_nodes(state) do
    nodes =
      Enum.sort([Node.self() | Node.list()])
      |> Enum.filter(fn node -> !ignore_node?(node, state.opts) end)

    case nodes == state.nodes do
      true ->
        state

      false ->
        Logger.debug("**** Node list updated to #{inspect(nodes)}")

        for mod <- [supervisor_name(state.sworm), registry_name(state.sworm)] do
          Horde.Cluster.set_members(mod, Enum.map(nodes, fn node -> {mod, node} end))
        end

        %State{state | nodes: nodes}
    end
  end

  @global_blacklist [~r/^remsh.*$/, ~r/^.+_upgrader_.+$/, ~r/^.+_maint_.+$/]

  # Determine if a node should be ignored, even if connected
  # The whitelist and blacklist can contain literal strings, regexes, or regex strings
  # By default, all nodes are allowed, except those which are remote shell sessions
  # where the node name of the remote shell starts with `remsh` (relx, exrm, and distillery)
  # all use that prefix for remote shells.
  defp ignore_node?(node, opts) do
    blacklist = Enum.uniq(@global_blacklist ++ (opts[:node_blacklist] || []))
    whitelist = opts[:node_whitelist] || []
    RingUtils.ignore_node?(node, blacklist, whitelist)
  end
end
