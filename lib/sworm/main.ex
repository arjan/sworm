defmodule Sworm.Main do
  @moduledoc false

  import Sworm.Util

  def child_spec(sworm, opts) do
    %{
      id: sworm,
      start: {Sworm.Supervisor, :start_link, [sworm, opts]},
      restart: :permanent,
      shutdown: 5000,
      type: :supervisor
    }
  end

  def register_name(sworm, name, m, f, a) do
    spec = %{
      id: name,
      start: {Sworm.Delegate, :start_link, [sworm, name, {m, f, a}]},
      type: :worker,
      restart: :transient,
      shutdown: 5000
    }

    with {:ok, delegate_pid} <- Horde.Supervisor.start_child(supervisor_name(sworm), spec) do
      GenServer.call(delegate_pid, :get_worker_pid)
    end
  end

  def whereis_or_register_name(sworm, name, m, f, a) do
    with :undefined <- whereis_name(sworm, name),
         {:ok, pid} <- register_name(sworm, name, m, f, a) do
      pid
    end
  end

  def unregister_name(sworm, name) do
    Horde.Supervisor.terminate_child(supervisor_name(sworm), name)
  end

  def whereis_name(sworm, name) do
    with [{_delegate, worker_pid}] <- Horde.Registry.lookup(registry_name(sworm), name) do
      worker_pid
    end
  end

  def registered(sworm) do
    Horde.Registry.processes(registry_name(sworm))
    |> Enum.map(fn {name, {_delegate_pid, worker_pid}} -> {name, worker_pid} end)
  end
end
