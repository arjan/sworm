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

  def start_link(sworm, opts \\ []) do
    %{start: {m, f, a}} = child_spec(sworm, opts)
    {:ok, _} = apply(m, f, a)
  end

  def register_name(sworm, name, m, f, a) do
    spec = %{
      id: name,
      start: {Sworm.Delegate, :start_link, [sworm, name, {m, f, a}]},
      type: :worker,
      restart: get_sworm_config(sworm, :restart, :transient),
      shutdown: 5000
    }

    with :undefined <- whereis_name(sworm, name),
         {:ok, delegate_pid} <- Horde.DynamicSupervisor.start_child(supervisor_name(sworm), spec) do
      GenServer.call(delegate_pid, :get_worker_pid)
    else
      pid when is_pid(pid) ->
        {:error, {:already_started, pid}}

      {:error, _} = e ->
        e

      :ignore ->
        # race lost
        {:error, {:already_started, whereis_name(sworm, name)}}
    end
  end

  def register_name(sworm, name, pid \\ self()) do
    reply =
      case lookup(sworm, {:worker, pid}) do
        [{delegate, nil}] -> GenServer.call(delegate, {:register_name, name})
        _ -> Sworm.Delegate.start(sworm, name, pid)
      end

    case reply do
      {:ok, _} -> :yes
      {:error, _} -> :no
    end
  end

  def whereis_or_register_name(sworm, name, m, f, a) do
    case whereis_name(sworm, name) do
      :undefined ->
        register_name(sworm, name, m, f, a)

      pid when is_pid(pid) ->
        {:ok, pid}
    end
  end

  def unregister_name(sworm, name) do
    case lookup(sworm, {:delegate, name}) do
      [{delegate, _worker}] ->
        Horde.DynamicSupervisor.terminate_child(supervisor_name(sworm), delegate)

      _ ->
        {:error, :not_found}
    end
  end

  def whereis_name(sworm, name) do
    case lookup(sworm, {:delegate, name}) do
      [{_delegate, worker_pid}] ->
        worker_pid

      _ ->
        :undefined
    end
  end

  def registered(sworm) do
    match = [{{{:delegate, :"$1"}, :"$2", :"$3"}, [], [{{:"$1", :"$3"}}]}]
    Horde.Registry.select(registry_name(sworm), match)
  end

  def members(sworm, group) do
    match = [{{{:group, group, :_}, :"$2", :"$3"}, [], [:"$3"]}]
    Horde.Registry.select(registry_name(sworm), match)
  end

  def join(sworm, group, worker \\ self()) do
    case lookup(sworm, {:worker, worker}) do
      [{delegate_pid, nil}] ->
        GenServer.call(delegate_pid, {:join, group})

      _ ->
        {:error, :not_found}
    end
  end

  def leave(sworm, group, worker \\ self()) do
    case lookup(sworm, {:worker, worker}) do
      [{delegate_pid, nil}] ->
        GenServer.call(delegate_pid, {:leave, group})

      _ ->
        {:error, :not_found}
    end
  end

  ###

  defp lookup(sworm, key) do
    Horde.Registry.lookup(registry_name(sworm), key)
  end
end
