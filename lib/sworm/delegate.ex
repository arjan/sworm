defmodule Sworm.Delegate do
  @moduledoc false

  use GenServer
  import Sworm.Util
  require Logger

  def start_link(sworm, name, mfa) do
    GenServer.start_link(__MODULE__, {sworm, name, mfa}, [])
  end

  def init({sworm, name, {m, f, a}}) do
    {:ok, pid} = apply(m, f, a)
    Process.monitor(pid)
    Horde.Registry.register(registry_name(sworm), name, pid)
    {:ok, pid}
  end

  def handle_call(:get_worker_pid, _from, pid) do
    {:reply, {:ok, pid}, pid}
  end

  def handle_info(message, state) do
    Logger.info("Got: #{inspect(message)}")

    {:noreply, state}
  end
end
