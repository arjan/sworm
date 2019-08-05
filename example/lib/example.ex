defmodule Example do
  defmodule TestServer do
    require Logger

    use GenServer

    def start_link() do
      GenServer.start_link(__MODULE__, [])
    end

    def init(a) do
      {:ok, a}
    end

    def handle_info({:begin_handoff, delegate, ref}, state) do
      Logger.info("begin handoff")

      send(delegate, {ref, :handoff_state, "asdf"})
      {:noreply, state}
    end
  end

  def process(name) do
    Example.Swarm.register_name(name, TestServer, :start_link, [])
  end

  defmodule Counter do
    require Logger

    use GenServer

    def start_link() do
      GenServer.start_link(__MODULE__, [])
    end

    def init(a) do
      :timer.send_interval(1000, :count)
      {:ok, 0}
    end

    def handle_info({Example.Swarm, :begin_handoff, delegate, ref}, state) do
      IO.puts("Begin handoff: #{state}")
      send(delegate, {ref, :handoff_state, state})
      {:noreply, state}
    end

    def handle_info({Example.Swarm, :end_handoff, state}, _state) do
      IO.puts("End handoff: #{state}")
      {:noreply, state}
    end

    def handle_info(:count, state) do
      IO.puts("Count: #{state}")
      {:noreply, state + 1}
    end
  end

  def counter(name) do
    Example.Swarm.register_name(name, Counter, :start_link, [])
  end

  def c do
    counter(:a)
  end

  def many do
    for n <- 1..10, do: counter(n)
  end
end
