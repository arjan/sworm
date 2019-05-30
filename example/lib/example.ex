defmodule Example do
  defmodule TestServer do
    use GenServer

    def start_link() do
      GenServer.start_link(__MODULE__, [])
    end

    def init(a) do
      IO.inspect(node(), label: "---- node()")

      {:ok, a}
    end
  end

  def process(name) do
    Example.Swarm.register_name(name, TestServer, :start_link, [])
  end
end
