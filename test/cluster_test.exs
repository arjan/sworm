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
  use SwormCase

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
          [[{"hi", p}], [{"hi", p}]],
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

  def custom_sworm() do
    Swurm.start_link(delta_crdt_options: [sync_interval: 5000])
  end

  sworm_scenario {__MODULE__, :custom_sworm, []},
                 "given a clean cluster for simultaneous registers",
                 cluster_size: 5 do
    test "many simultaneous registers for the same name always result in a valid pid", %{
      cluster: c
    } do
      [_, _, _, _, _] = Cluster.members(c)

      n_start = 100

      results =
        for n <- 1..200 do
          node = Cluster.random_member(c)

          Task.async(fn ->
            Process.sleep(Enum.random(1..100))

            Cluster.call(node, Swurm, :start_many, ["hi_#{n}", n_start])
            |> Enum.sort()
            |> Enum.reverse()
          end)
        end
        |> Task.await_many(20_000)

      for start_results <- results do
        [{:ok, pid} | rest] = start_results
        assert length(rest) == n_start - 1
        assert [{:error, {:already_started, ^pid}}] = Enum.uniq(rest)
      end
    end
  end

  sworm_scenario Swurm, "given another cluster for simultaneous registers", cluster_size: 2 do
    test "whereis_name always returns either a pid or undefined", %{
      cluster: c
    } do
      [a, b] = Cluster.members(c)

      ta =
        Task.async(fn ->
          Cluster.call(a, fn ->
            for _ <- 1..1000 do
              Process.sleep(3)
              Swurm.whereis_name("test1")
            end
          end)
        end)

      tb =
        Task.async(fn ->
          Cluster.call(b, fn ->
            Swurm.start_one("test1")
          end)
        end)

      [r, {:ok, pid}] = Task.await_many([ta, tb])

      r = r |> Enum.reject(&(&1 == :undefined)) |> Enum.uniq()
      assert r == [pid]
    end
  end

  sworm_scenario Swurm, "given a cluster that is shutting down" do
    test "register process on one server; process moves to other node when it goes down", %{
      cluster: c
    } do
      n = Cluster.random_member(c)
      Cluster.call(n, Swurm, :start_one, ["hi"])

      until_match([_], Cluster.call(n, Swurm, :registered, []))

      [{"hi", pid}] = Cluster.call(n, Swurm, :registered, [])

      target_node = node(pid)
      [other_node] = Cluster.members(c) -- [target_node]

      until_match(
        [{"hi", ^pid}],
        Cluster.call(other_node, Swurm, :registered, [])
      )

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

      until_match([_, _], Cluster.call(a, Sworm.DirectoryManager, :nodes_for_sworm, [Swurm]))

      Cluster.stop_node(c, b)

      until_match([_], Cluster.call(a, Sworm.DirectoryManager, :nodes_for_sworm, [Swurm]))
    end
  end

  require Logger

  sworm_scenario Swurm, "given a partitioned cluster" do
    test "resolves name conflicts", %{cluster: c} do
      [a, b] = Cluster.members(c)
      Cluster.partition(c, [[a], [b]])

      assert {:ok, pid_a} = Cluster.call(a, Swurm, :start_one, ["hi"])
      assert {:ok, pid_b} = Cluster.call(b, Swurm, :start_one, ["hi"])

      assert pid_a != pid_b

      Process.sleep(500)

      Cluster.heal(c)

      wait_until(fn ->
        case {Cluster.call(a, Swurm, :registered, []), Cluster.call(b, Swurm, :registered, [])} do
          {[{"hi", pid}], [{"hi", pid}]} ->
            true

          _ ->
            false
        end
      end)

      # we now have only one pid
      [{"hi", pid}] = Cluster.call(a, Swurm, :registered, [])
      [{"hi", ^pid}] = Cluster.call(b, Swurm, :registered, [])

      # stop it before exiting
      GenServer.stop(pid)

      until_match([], Cluster.call(a, Swurm, :registered, []))
      until_match([], Cluster.call(b, Swurm, :registered, []))
    end
  end
end
