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

  defmodule TempSworm do
    use Sworm, restart: :temporary
  end

  test "Support child restart strategy - restart: transient (default)" do
    assert {:ok, _} = AnotherSworm.start_link()
    assert [] = AnotherSworm.registered()

    assert {:ok, worker} =
             AnotherSworm.whereis_or_register_name("test", TestServer, :start_link, [])

    assert [{"test", ^worker}] = AnotherSworm.registered()

    Process.exit(worker, :kill)
    Process.sleep(200)

    assert [{"test", worker2}] = AnotherSworm.registered()

    assert worker != worker2
  end

  defmodule TempSworm do
    use Sworm, restart: :temporary
  end

  test "Support child restart strategy - restart: temporary" do
    assert {:ok, _} = TempSworm.start_link()
    assert [] = TempSworm.registered()

    assert {:ok, worker} = TempSworm.whereis_or_register_name("test", TestServer, :start_link, [])

    assert [{"test", ^worker}] = TempSworm.registered()

    Process.exit(worker, :kill)
    Process.sleep(200)

    assert [] = TempSworm.registered()
  end
end
