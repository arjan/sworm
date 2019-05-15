defmodule Example.Worker do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end
end
