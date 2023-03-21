defmodule Sworm.ErrorTests do
  use SwormCase

  setup do
    # start it
    sworm(TestSworm)

    :ok
  end

  defmodule CrashingServer do
    use GenServer

    def start_link() do
      GenServer.start_link(__MODULE__, [])
    end

    def init([]), do: {:stop, :cannot_start}
  end

  test "supervisor" do
    assert [] = Sworm.registered(TestSworm)

    assert {:error, :cannot_start} =
             Sworm.register_name(TestSworm, "foo", CrashingServer, :start_link, [])
  end
end
