defmodule MySwarm do
  use Sworm

  defmodule TestServer do
    use GenServer

    def start_link() do
      GenServer.start_link(__MODULE__, [])
    end

    def init(a) do
      {:ok, a}
    end
  end

  def start_one(name) do
    MySwarm.register_name(name, TestServer, :start_link, [])
  end
end

defmodule Sworm.DirectoryManagerTest do
  use ExUnit.ClusteredCase

  import Sworm.Support.Helpers

  scenario "given a cluster with 2 nodes",
    cluster_size: 2,
    boot_timeout: 20_000,
    stdout: :standard_error do
    node_setup do
      {:ok, _} = Application.ensure_all_started(:sworm)
      {:ok, pid} = MySwarm.start_link()
      Process.unlink(pid)

      :ok
    end

    test "directory is updated when nodes join and leave", %{
      cluster: c
    } do
      [a, b] = Cluster.members(c)

      wait_until(fn ->
        match?([_, _], Cluster.call(a, Sworm.DirectoryManager, :nodes_for_sworm, [MySwarm]))
      end)

      IO.puts("--------------------------------------------------------")

      # stop_node(c, b)
      Cluster.partition(c, 2)

      wait_until(fn ->
        match?([_], Cluster.call(a, Sworm.DirectoryManager, :nodes_for_sworm, [MySwarm]))
      end)

      IO.puts("--------------------------------------------------------")

      # stop_node(c, b)
      Cluster.heal(c)

      wait_until(fn ->
        match?([_, _], Cluster.call(a, Sworm.DirectoryManager, :nodes_for_sworm, [MySwarm]))
      end)
    end
  end
end
