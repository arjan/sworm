defmodule Sworm.DirectoryManager do
  @moduledoc false

  @selector [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$3"}}]}]

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def register(sworm) do
    GenServer.call(__MODULE__, {:register, sworm})
  end

  def nodes_for_sworm(sworm) do
    Horde.Registry.select(Sworm.Directory, @selector)
    |> Enum.map(fn
      {{^sworm, node}, :alive} -> node
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort()
  end

  ###

  require Logger

  def init([]) do
    :net_kernel.monitor_nodes(true, [])
    {:ok, update_nodes([])}
  end

  def handle_call({:register, sworm}, _from, state) do
    # register this sworm in the Sworm Directory
    reply = Horde.Registry.register(Sworm.Directory, {sworm, node()}, :alive)

    {:reply, reply, state}
  end

  def handle_info({node_event, _node}, state)
      when node_event == :nodeup or node_event == :nodedown do
    {:noreply, update_nodes(state)}
  end

  def handle_info(_request, state) do
    {:noreply, state}
  end

  def update_nodes(state) do
    nodes = Node.list([:this, :visible]) |> Enum.sort()

    case nodes == state do
      true ->
        state

      false ->
        Logger.info("Node directory list updated to #{inspect(nodes)}")
        Horde.Cluster.set_members(Sworm.Directory, Enum.map(nodes, &{Sworm.Directory, &1}))

        # remove all entries from directory which are not part of the current nodes
        for {{_sworm, node} = key, status} <- Horde.Registry.select(Sworm.Directory, @selector) do
          node_ok = Enum.member?(nodes, node)

          case status do
            :alive when node_ok ->
              :ok

            :alive ->
              # need to filter it, temporarily; node might reappear
              register_or_update(key, {:dead, now()})

            {:dead, _ts} when node_ok ->
              # it reappeared; set it to alive again
              register_or_update(key, :alive)

            {:dead, ts} ->
              if now() - ts > 3600_000 do
                # too long; unregister the service for good.
                Horde.Registry.unregister(Sworm.Directory, key)
              end

              :ok
          end
        end

        nodes
    end
  end

  defp register_or_update(key, value) do
    with {:error, {:already_registered, _}} <-
           Horde.Registry.register(Sworm.Directory, key, value) do
      Horde.Registry.update_value(Sworm.Directory, key, fn _ -> value end)
    end
  end

  defp now(), do: :erlang.system_time(:millisecond)
end
