defmodule Example.Worker do
  use GenServer

  def mass_start(name, n \\ 10) do
    for _ <- 1..n do
      Task.async(fn ->
        Example.Swarm.register_name(name, __MODULE__, :start_link, [])
      end)
    end
    |> Task.await_many()
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end
end
