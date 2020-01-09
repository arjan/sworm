defmodule SwormTest do
  use ExUnit.Case, async: false
  doctest Sworm

  setup do
    # start it
    sworm(TestSworm)

    :ok
  end

  defmodule TestServer do
    use GenServer

    def start_link() do
      GenServer.start_link(__MODULE__, [])
    end

    def init([]), do: {:ok, nil}

    def handle_call(:x, _from, state) do
      {:reply, :y, state}
    end
  end

  test "supervisor" do
    assert [] = Sworm.registered(TestSworm)

    assert {:ok, worker} = Sworm.register_name(TestSworm, "foo", TestServer, :start_link, [])

    assert [{"foo", ^worker}] = Sworm.registered(TestSworm)
    assert :y = GenServer.call(worker, :x)

    assert ^worker = Sworm.whereis_name(TestSworm, "foo")

    assert {:error, :not_found} = Sworm.unregister_name(TestSworm, "z")
    assert :ok = Sworm.unregister_name(TestSworm, "foo")
    assert :undefined = Sworm.whereis_name(TestSworm, "foo")

    refute Process.alive?(worker)
  end

  test "whereis_or_register_name" do
    assert :undefined = Sworm.whereis_name(TestSworm, "test")

    {:ok, worker} = Sworm.whereis_or_register_name(TestSworm, "test", TestServer, :start_link, [])
    assert is_pid(worker)

    assert ^worker = Sworm.whereis_name(TestSworm, "test")

    assert [{"test", ^worker}] = Sworm.registered(TestSworm)
    assert :y = GenServer.call(worker, :x)
  end

  test "join / leave / members" do
    assert {:error, :not_found} = Sworm.join(TestSworm, "group1", self())
    assert {:error, :not_found} = Sworm.leave(TestSworm, "group1", self())

    assert [] = Sworm.members(TestSworm, "group1")
    assert {:ok, worker} = Sworm.register_name(TestSworm, "a", TestServer, :start_link, [])

    assert :ok = Sworm.join(TestSworm, "group1", worker)
    assert [^worker] = Sworm.members(TestSworm, "group1")

    assert {:ok, worker} = Sworm.register_name(TestSworm, "b", TestServer, :start_link, [])

    assert :ok = Sworm.join(TestSworm, "group1", worker)
    assert [_, _] = Sworm.members(TestSworm, "group1")

    assert :ok = Sworm.leave(TestSworm, "group1", worker)
    assert [_] = Sworm.members(TestSworm, "group1")

    # leave/join multiple times is OK
    assert :ok = Sworm.join(TestSworm, "group1", worker)
    assert :ok = Sworm.join(TestSworm, "group1", worker)

    assert :ok = Sworm.leave(TestSworm, "group1", worker)
    assert :ok = Sworm.leave(TestSworm, "group1", worker)
    assert :ok = Sworm.leave(TestSworm, "group1", worker)
  end

  defmodule NameTestServer do
    def init(name) do
      :yes = Sworm.register_name(TestSworm, name)
      {:ok, nil}
    end
  end

  test "register_name/2" do
    {:ok, _} = GenServer.start_link(NameTestServer, "a", [])
    {:ok, b} = GenServer.start_link(NameTestServer, "b", [])

    assert [{"a", _}, {"b", _}] = Sworm.registered(TestSworm) |> Enum.sort()

    GenServer.stop(b)
    Process.sleep(100)

    assert [{"a", _}] = Sworm.registered(TestSworm)
  end

  test "register_name/3" do
    me = self()
    :yes = Sworm.register_name(TestSworm, "a", me)

    assert [{"a", ^me}] = Sworm.registered(TestSworm)
    assert [_] = delegates()

    # cannot register again
    :no = Sworm.register_name(TestSworm, "a", me)

    # ensure we have only one delegate
    assert [_] = delegates()

    :yes = Sworm.register_name(TestSworm, "b", me)

    # still only one delegate
    assert [_] = delegates()
  end

  test "remove from supervisor on name conflict" do
    # Simulate a network partition healing, 2 processes registered on
    # different nodes are reconciled.

    sworm(A)
    sworm(B)

    assert {:ok, pid_a} = Sworm.register_name(A, "foo", TestServer, :start_link, [])
    Process.sleep(10)
    assert {:ok, pid_b} = Sworm.register_name(B, "foo", TestServer, :start_link, [])

    Horde.Cluster.set_members(A.Registry, [A.Registry, B.Registry])
    Horde.Cluster.set_members(A.Supervisor, [A.Supervisor, B.Supervisor])

    Process.sleep(200)

    refute Process.alive?(pid_a)
    assert Process.alive?(pid_b)

    assert([{"foo", ^pid_b}] = Sworm.registered(A))
    assert([{"foo", ^pid_b}] = Sworm.registered(B))

    assert [{:undefined, _delegate, _, _}] = Horde.DynamicSupervisor.which_children(A.Supervisor)
    assert [{:undefined, _delegate, _, _}] = Horde.DynamicSupervisor.which_children(B.Supervisor)
  end

  def delegates() do
    match = [{{{:delegate, :"$1"}, :"$2", :"$3"}, [], [:"$3"]}]

    Horde.Registry.select(TestSworm.Registry, match)
    |> Enum.uniq()
  end

  test "register_name race" do
    parent = self()

    for n <- 1..10 do
      spawn_link(fn ->
        result = Sworm.register_name(TestSworm, "a", TestServer, :start_link, [])
        send(parent, result)
      end)
    end

    all = mailbox() |> Enum.reverse()

    assert [
             {:ok, p},
             {:error, {:already_started, p}},
             {:error, {:already_started, p}},
             {:error, {:already_started, p}},
             {:error, {:already_started, p}},
             {:error, {:already_started, p}},
             {:error, {:already_started, p}},
             {:error, {:already_started, p}},
             {:error, {:already_started, p}},
             {:error, {:already_started, p}}
           ] = all
  end

  defp mailbox() do
    mailbox([])
  end

  defp mailbox(rest) do
    receive do
      item -> mailbox([item | rest])
    after
      100 -> rest
    end
  end

  ###

  defp sworm(name) do
    {:ok, pid} = Sworm.start_link(name)

    on_exit(fn ->
      Process.sleep(50)
      Process.exit(pid, :normal)
      Process.sleep(200)
    end)
  end
end
