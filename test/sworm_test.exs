defmodule SwormTest do
  use ExUnit.Case
  doctest Sworm

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
    {:ok, pid} = Sworm.Supervisor.start_link({Foo, []})

    assert [] = Sworm.registered(Foo)

    assert {:ok, worker} = Sworm.register_name(Foo, "foo", TestServer, :start_link, [])

    assert [{"foo", ^worker}] = Sworm.registered(Foo)
    assert :y = GenServer.call(worker, :x)

    assert ^worker = Sworm.whereis_name(Foo, "foo")

    assert {:error, :not_found} = Sworm.unregister_name(Foo, "z")
    assert :ok = Sworm.unregister_name(Foo, "foo")
    assert :undefined = Sworm.whereis_name(Foo, "foo")

    refute Process.alive?(worker)
  end

  test "whereis_or_register_name" do
    {:ok, pid} = Sworm.Supervisor.start_link({Foo, []})

    assert :undefined = Sworm.whereis_name(Foo, "test")

    worker = Sworm.whereis_or_register_name(Foo, "test", TestServer, :start_link, [])
    assert is_pid(worker)

    assert ^worker = Sworm.whereis_name(Foo, "test")

    assert [{"test", ^worker}] = Sworm.registered(Foo)
    assert :y = GenServer.call(worker, :x)
  end
end
