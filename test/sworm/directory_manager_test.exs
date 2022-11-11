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
  use SwormCase

  import Sworm.Support.Helpers

  sworm_scenario MySwarm, "given a cluster with 2 nodes" do
    test "directory is updated when nodes join and leave", %{
      cluster: c
    } do
      [a, _b] = Cluster.members(c)

      until_match([_, _], Cluster.call(a, Sworm.DirectoryManager, :nodes_for_sworm, [MySwarm]))

      # stop_node(c, b)
      Cluster.partition(c, 2)

      until_match([_], Cluster.call(a, Sworm.DirectoryManager, :nodes_for_sworm, [MySwarm]))

      # stop_node(c, b)
      Cluster.heal(c)

      until_match([_, _], Cluster.call(a, Sworm.DirectoryManager, :nodes_for_sworm, [MySwarm]))
    end
  end
end
