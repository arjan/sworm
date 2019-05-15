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
    {:ok, _pid} = Sworm.Supervisor.start_link(Sworm1, [])

    assert [] = Sworm.registered(Sworm1)

    assert {:ok, worker} = Sworm.register_name(Sworm1, "foo", TestServer, :start_link, [])

    assert [{"foo", ^worker}] = Sworm.registered(Sworm1)
    assert :y = GenServer.call(worker, :x)

    assert ^worker = Sworm.whereis_name(Sworm1, "foo")

    assert {:error, :not_found} = Sworm.unregister_name(Sworm1, "z")
    assert :ok = Sworm.unregister_name(Sworm1, "foo")
    assert :undefined = Sworm.whereis_name(Sworm1, "foo")

    refute Process.alive?(worker)
  end

  test "whereis_or_register_name" do
    {:ok, _pid} = Sworm.Supervisor.start_link(Sworm2, [])

    assert :undefined = Sworm.whereis_name(Sworm2, "test")

    worker = Sworm.whereis_or_register_name(Sworm2, "test", TestServer, :start_link, [])
    assert is_pid(worker)

    assert ^worker = Sworm.whereis_name(Sworm2, "test")

    assert [{"test", ^worker}] = Sworm.registered(Sworm2)
    assert :y = GenServer.call(worker, :x)
  end

  defmodule MySworm do
    use Sworm
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
  end
end
