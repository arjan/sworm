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

  scenario "given a healthy cluster",
    cluster_size: 3,
    boot_timeout: 20_000,
    stdout: :standard_error do
    node_setup do
      {:ok, pid} = Swurm.start_link()
      Process.unlink(pid)

      :ok
    end

    test "can call on all nodes", %{cluster: c} do
      assert [[], [], []] =
               Cluster.members(c) |> Enum.map(fn n -> Cluster.call(n, Swurm, :registered, []) end)
    end

    test "register process on one server; registration is propagated to other nodes", %{
      cluster: c
    } do
      n = Cluster.random_member(c)
      Cluster.call(n, Swurm, :start_one, ["hi"])

      # settle
      Process.sleep(200)

      assert [[{"hi", p}], [{"hi", p}], [{"hi", p}]] =
               Cluster.members(c) |> Enum.map(fn n -> Cluster.call(n, Swurm, :registered, []) end)

      GenServer.stop(p)

      # settle
      Process.sleep(200)

      assert [[], [], []] =
               Cluster.members(c) |> Enum.map(fn n -> Cluster.call(n, Swurm, :registered, []) end)
    end
  end
end
