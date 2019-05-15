defmodule Sworm.MacroTest do
  use ExUnit.Case

  defmodule MySworm do
    use Sworm
  end

  defmodule TestServer do
    use GenServer
    alias Sworm.MacroTest.MySworm

    def start_link() do
      GenServer.start_link(__MODULE__, [])
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

    def handle_call(:x, _from, state) do
      {:reply, :y, state}
    end
  end

  test "using" do
    # start it
    assert %{start: {m, f, a}} = MySworm.child_spec([])
    {:ok, _pid} = apply(m, f, a)

    assert [] = MySworm.registered()

    assert :undefined = MySworm.whereis_name("test")

    worker = MySworm.whereis_or_register_name("test", TestServer, :start_link, [])
    assert is_pid(worker)

    assert ^worker = MySworm.whereis_name("test")

    assert [{"test", ^worker}] = MySworm.registered()
    assert :y = GenServer.call(worker, :x)

    assert [] = MySworm.members("group0")
    :ok = GenServer.call(worker, {:join, "group0"})
    assert [^worker] = MySworm.members("group0")
    :ok = GenServer.call(worker, {:leave, "group0"})
    assert [] = MySworm.members("group0")
  end
end