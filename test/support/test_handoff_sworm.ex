defmodule HandoffSworm do
  @moduledoc false

  use Sworm, handoff: true

  defmodule TestServer do
    use GenServer

    def start_link() do
      GenServer.start_link(__MODULE__, 0)
    end

    def init(state) do
      {:ok, state}
    end

    def handle_call(:inc, _from, state) do
      state = state + 1
      {:reply, state, state}
    end

    def handle_call(:get, _from, state) do
      {:reply, state, state}
    end

    def handle_info({HandoffSworm, :begin_handoff, delegate, ref}, state) do
      send(delegate, {ref, :handoff_state, state})
      {:noreply, state}
    end

    def handle_info({HandoffSworm, :end_handoff, state}, _state) do
      {:noreply, state}
    end
  end

  def start_one(name) do
    HandoffSworm.register_name(name, TestServer, :start_link, [])
  end
end
