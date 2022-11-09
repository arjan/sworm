defmodule Swurm do
  use Sworm

  defmodule TestServer do
    use GenServer
    require Logger

    def start_link() do
      GenServer.start_link(__MODULE__, [])
    end

    def init(a) do
      Process.flag(:trap_exit, true)
      {:ok, a}
    end

    def handle_info(message, state) do
      Logger.warn("*** #{inspect(message)}")

      {:noreply, state}
    end
  end

  def start_one(name) do
    Swurm.register_name(name, TestServer, :start_link, [])
  end

  def start_many(name, n \\ 10) do
    for _ <- 1..n do
      Task.async(fn -> start_one(name) end)
    end
    |> Task.await_many()
  end
end

defmodule SwormClusterTest do
  use ExUnit.ClusteredCase

  import Sworm.Support.Helpers

  sworm_scenario Swurm, "given a healthy cluster" do
    test "can call on all nodes", %{cluster: c} do
      assert [[], []] =
               Cluster.members(c) |> Enum.map(fn n -> Cluster.call(n, Swurm, :registered, []) end)
    end

    test "register process on one server; registration is propagated to other nodes", %{
      cluster: c
    } do
      n = Cluster.random_member(c)
      Cluster.call(n, Swurm, :start_one, ["hi"])

      # settle
      wait_until(fn ->
        match?(
          [[{"hi", _}], [{"hi", _}]],
          Cluster.members(c) |> Enum.map(fn n -> Cluster.call(n, Swurm, :registered, []) end)
        )
      end)

      # now stop it
      [[{"hi", p}] | _] =
        Cluster.members(c) |> Enum.map(fn n -> Cluster.call(n, Swurm, :registered, []) end)

      GenServer.stop(p)

      # settle

      wait_until(fn ->
        [[], []] ==
          Cluster.members(c) |> Enum.map(fn n -> Cluster.call(n, Swurm, :registered, []) end)
      end)
    end
  end

  sworm_scenario Swurm, "given a clean cluster for simultaneous registers" do
    test "many simultaneous registers for the same name always result in a valid pid", %{
      cluster: c
    } do
      [_, _] = Cluster.members(c)

      results =
        for n <- 1..20 do
          node = Cluster.random_member(c)

          Task.async(fn ->
            Cluster.call(node, Swurm, :start_many, ["hi_#{n}"])
            |> Enum.sort()
          end)
        end
        |> Task.await_many()

      for start_results <- results do
        assert {:ok, pid} = List.last(start_results)
        assert is_pid(pid)
        assert {:error, {:already_started, ^pid}} = List.first(start_results)
      end

      Process.sleep(2000)
    end
  end

  sworm_scenario Swurm, "given a cluster that is shutting down" do
    test "register process on one server; process moves to other node when it goes down", %{
      cluster: c
    } do
      n = Cluster.random_member(c)
      Cluster.call(n, Swurm, :start_one, ["hi"])

      wait_until(fn ->
        match?([_], Cluster.call(n, Swurm, :registered, []))
      end)

      [{"hi", pid}] = Cluster.call(n, Swurm, :registered, [])

      target_node = node(pid)
      [other_node] = Cluster.members(c) -- [target_node]

      wait_until(fn ->
        [{"hi", pid}] == Cluster.call(other_node, Swurm, :registered, [])
      end)

      Cluster.stop_node(c, target_node)

      wait_until(fn ->
        [{"hi", pid}] = Cluster.call(other_node, Swurm, :registered, [])

        # process now runs on the other node
        node(pid) == other_node
      end)
    end
  end

  sworm_scenario Swurm, "directory" do
    test "directory is updated when nodes join and leave", %{
      cluster: c
    } do
      [a, b] = Cluster.members(c)

      wait_until(fn ->
        match?([_, _], Cluster.call(a, Sworm.DirectoryManager, :nodes_for_sworm, [Swurm]))
      end)

      Cluster.stop_node(c, b)

      wait_until(fn ->
        match?([_], Cluster.call(a, Sworm.DirectoryManager, :nodes_for_sworm, [Swurm]))
      end)
    end
  end
end
