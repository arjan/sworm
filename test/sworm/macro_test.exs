defmodule Sworm.MacroTest do
  use ExUnit.Case

  defmodule MySworm do
    use Sworm
  end

  defmodule TestServer do
    use GenServer
    alias Sworm.MacroTest.MySworm

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, [], opts)
    end

    def init([]), do: {:ok, nil}

    def handle_call({:join, group}, _from, state) do
      MySworm.join(group)
      {:reply, :ok, state}
    end

    def handle_call({:leave, group}, _from, state) do
      MySworm.leave(group)
      {:reply, :ok, state}
    end

    def handle_call(:ping, _from, state) do
      {:reply, :pong, state}
    end
  end

  setup do
    # start it
    {:ok, pid} = MySworm.start_link()

    on_exit(fn ->
      Process.sleep(50)
      Process.exit(pid, :normal)
    end)

    :ok
  end

  test "using" do
    assert [] = MySworm.registered()

    assert :undefined = MySworm.whereis_name("test")

    assert {:ok, worker} = MySworm.whereis_or_register_name("test", TestServer, :start_link, [])
    assert is_pid(worker)

    assert ^worker = MySworm.whereis_name("test")

    assert [{"test", ^worker}] = MySworm.registered()
    assert :pong = GenServer.call(worker, :ping)

    assert [] = MySworm.members("group0")
    :ok = GenServer.call(worker, {:join, "group0"})
    assert [^worker] = MySworm.members("group0")
    :ok = GenServer.call(worker, {:leave, "group0"})
    assert [] = MySworm.members("group0")
  end

  test "register_name/1" do
    assert [] = MySworm.registered()

    assert :yes = MySworm.register_name("hello")
    # assert :yes = MySworm.register_name("hello1")
    pid = self()
    assert [{"hello", ^pid}] = MySworm.registered()
  end

  test "via tuple" do
    name = {:via, MySworm, "test_server"}
    {:ok, pid} = TestServer.start_link(name: name)
    assert [{"test_server", ^pid}] = MySworm.registered()
    assert :pong = GenServer.call(name, :ping)
  end

  defmodule AnotherSworm do
    use Sworm
  end

  test "start/0" do
    assert {:ok, _} = AnotherSworm.start_link()
    assert [] = AnotherSworm.registered()
  end
end
