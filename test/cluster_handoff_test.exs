defmodule SwormClusterHandoffTest do
  use ExUnit.ClusteredCase

  import Sworm.Support.Helpers

  scenario "given a healthy cluster",
    cluster_size: 2,
    boot_timeout: 20_000,
    stdout: :standard_error do
    node_setup do
      {:ok, _} = Application.ensure_all_started(:sworm)

      :ok
    end

    test "state is propagated when process moves to another server on node shutdown", %{
      cluster: c
    } do
      n = Cluster.random_member(c)

      Cluster.call(n, HandoffSworm, :start_one, ["hi"])

      # settle
      wait_until(fn ->
        match?(
          [[{"hi", _}], [{"hi", _}]],
          Cluster.members(c)
          |> Enum.map(fn n -> Cluster.call(n, HandoffSworm, :registered, []) end)
        )
      end)

      [[{_, pid}] | _] =
        Cluster.members(c) |> Enum.map(fn n -> Cluster.call(n, HandoffSworm, :registered, []) end)

      # set some state
      assert 0 == GenServer.call(pid, :get)
      assert 1 == GenServer.call(pid, :inc)
      assert 2 == GenServer.call(pid, :inc)
      assert 3 == GenServer.call(pid, :inc)
      assert 4 == GenServer.call(pid, :inc)

      Cluster.stop_node(c, node(pid))

      [other] = Cluster.members(c) -- [node(pid)]

      wait_until(fn ->
        [{"hi", pid}] = Cluster.call(other, HandoffSworm, :registered, [])

        # process now runs on the other node
        node(pid) == other
      end)

      # get the new pid
      [{"hi", pid}] = Cluster.call(other, HandoffSworm, :registered, [])

      # ensure that the state has been moved through the handoff process
      wait_until(fn ->
        4 == GenServer.call(pid, :get)
      end)
    end
  end
end
