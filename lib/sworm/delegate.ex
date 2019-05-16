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
    defstruct [:pid, :sworm]
  end

  def init({sworm, name, mfa_or_pid}) do
    {:ok, pid} =
      case mfa_or_pid do
        {m, f, a} -> apply(m, f, a)
        pid when is_pid(pid) -> {:ok, pid}
      end

    Process.monitor(pid)
    Horde.Registry.register(registry_name(sworm), {:delegate, name}, pid)
    Horde.Registry.register(registry_name(sworm), {:worker, pid}, nil)
    {:ok, %State{pid: pid, sworm: sworm}}
  end

  def handle_call(:get_worker_pid, _from, state) do
    {:reply, {:ok, state.pid}, state}
  end

  def handle_call({:join, group}, _from, state) do
    {:ok, _} = Horde.Registry.register(registry_name(state.sworm), {:group, group}, state.pid)
    {:reply, :ok, state}
  end

  def handle_call({:leave, group}, _from, state) do
    :ok = Horde.Registry.unregister(registry_name(state.sworm), {:group, group})
    {:reply, :ok, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, %State{pid: pid} = state) do
    {:stop, :normal, state}
  end

  def handle_info(message, state) do
    Logger.debug("Got unexpected info message: #{inspect(message)}")
    {:noreply, state}
  end
end
