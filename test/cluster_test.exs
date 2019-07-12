defmodule Swurm do
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
    Swurm.register_name(name, TestServer, :start_link, [])
  end
end

defmodule SwormClusterTest do
  use ExUnit.ClusteredCase

  import Sworm.Support.Helpers

  scenario "given a healthy cluster",
    cluster_size: 2,
    boot_timeout: 20_000,
    stdout: :standard_error do
    node_setup do
      {:ok, _} = Application.ensure_all_started(:telemetry)
      {:ok, pid} = Swurm.start_link()
      Process.unlink(pid)

      :ok
    end

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

  scenario "given a cluster that is shutting down",
    cluster_size: 2,
    boot_timeout: 20_000,
    stdout: :standard_error do
    node_setup do
      {:ok, _} = Application.ensure_all_started(:horde)
      {:ok, pid} = Swurm.start_link()
      Process.unlink(pid)

      :ok
    end

    test "register process on one server; process moves to other node when it goes down", %{
      cluster: c
    } do
      n = Cluster.random_member(c)
      Cluster.call(n, Swurm, :start_one, ["hi"])

      Process.sleep(300)
      [{"hi", pid}] = Cluster.call(n, Swurm, :registered, [])

      target_node = node(pid)
      [other_node] = Cluster.members(c) -- [target_node]

      [{"hi", ^pid}] = Cluster.call(other_node, Swurm, :registered, [])

      Cluster.stop_node(c, target_node)

      wait_until(fn ->
        [{"hi", pid}] = Cluster.call(other_node, Swurm, :registered, [])

        # process now runs on the other node
        node(pid) == other_node
      end)
    end
  end
end
