defmodule Sworm.ShutdownTest do
  use ExUnit.Case

  defmodule MySworm do
    use Sworm

    defmodule TestServer do
      use GenServer
      alias Sworm.MacroTest.MySworm

      def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, [], opts)
      end

      def init([]), do: {:ok, nil}
    end
  end

  test "shut down" do
    {:ok, pid} = MySworm.start_link([])
    Process.unlink(pid)

    {:ok, _} = MySworm.register_name("hoi", MySworm.TestServer, :start_link, [])

    [_] = MySworm.registered()

    :ok = Supervisor.stop(pid, :shutdown)
  end
end
