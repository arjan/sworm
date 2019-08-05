defmodule Sworm.Delegate do
  @moduledoc false

  use GenServer
  import Sworm.Util
  require Logger

  def start_link(sworm, name, mfa_or_pid) do
    GenServer.start_link(__MODULE__, {sworm, name, mfa_or_pid}, [])
  end

  def start(sworm, name, mfa_or_pid) do
    GenServer.start(__MODULE__, {sworm, name, mfa_or_pid}, [])
  end

  ###

  defmodule State do
    @moduledoc false

    defstruct [:pid, :name, :sworm]
  end

  @impl GenServer
  def init({sworm, name, mfa_or_pid}) do
    Process.flag(:trap_exit, true)

    {:ok, pid} =
      case mfa_or_pid do
        {m, f, a} -> apply(m, f, a)
        pid when is_pid(pid) -> {:ok, pid}
      end

    Process.monitor(pid)

    check_end_handoff(pid, sworm, name)

    with {:ok, _} <- Horde.Registry.register(registry_name(sworm), {:delegate, name}, pid) do
      Horde.Registry.register(registry_name(sworm), {:worker, pid}, nil)
      {:ok, %State{pid: pid, name: name, sworm: sworm}}
    else
      {:error, {:already_registered, pid}} ->
        Logger.warn("already registered :#{inspect(name)}, to #{inspect(pid)}, bail out")
        :ignore
    end
  end

  @impl true
  def handle_call(:get_worker_pid, _from, state) do
    {:reply, {:ok, state.pid}, state}
  end

  def handle_call({:register_name, name}, _from, state) do
    reply = Horde.Registry.register(registry_name(state.sworm), {:delegate, name}, state.pid)
    {:reply, reply, state}
  end

  def handle_call({:join, group}, _from, state) do
    {:ok, _} = Horde.Registry.register(registry_name(state.sworm), {:group, group}, state.pid)
    {:reply, :ok, state}
  end

  def handle_call({:leave, group}, _from, state) do
    :ok = Horde.Registry.unregister(registry_name(state.sworm), {:group, group})
    {:reply, :ok, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, %State{pid: pid} = state) do
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, _, :shutdown}, state) do
    {:stop, :shutdown, state}
  end

  def handle_info({:EXIT, _, {:name_conflict, {_name, _}, _reg, _winner} = r}, state) do
    {:stop, r, state}
  end

  def handle_info(message, state) do
    Logger.info("Delegate #{inspect(self())} Got unexpected info message: #{inspect(message)}")
    {:noreply, state}
  end

  @impl true
  def terminate(:shutdown, state) do
    if get_sworm_config(state.sworm, :handoff, false) do
      perform_begin_handoff(state)
    end
  end

  def terminate(_reason, _state) do
    :ok
  end

  ###

  defp perform_begin_handoff(state) do
    Logger.info("Delegate #{inspect(self())} state handoff")

    ref = make_ref()
    send(state.pid, {state.sworm, :begin_handoff, self(), ref})

    receive do
      {^ref, :ignore} ->
        :ok

      {^ref, :handoff_state, data} ->
        Horde.Registry.register(registry_name(state.sworm), {:handoff_state, state.name}, data)
        # give CRDT some time to propagate before we shut down
        Process.sleep(2000)

        :ok
    after
      1000 ->
        :ok
    end

    :ok
  end

  defp check_end_handoff(pid, sworm, name) do
    Horde.Registry.select(registry_name(sworm), [
      {{{:handoff_state, name}, :"$1", :"$2"}, [], [{{:"$2"}}]}
    ])
    |> case do
      [] ->
        :ok

      [{state}] ->
        # notify the worker to restore itself
        send(pid, {sworm, :end_handoff, state})
    end
  end
end
