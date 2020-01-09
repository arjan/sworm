defmodule Sworm.Supervisor do
  @moduledoc false
  @behaviour Supervisor

  require Logger
  import Sworm.Util

  def start_link(sworm, opts) do
    Supervisor.start_link(__MODULE__, {sworm, opts}, name: sworm)
  end

  @impl true
  def init({sworm, _opts} = arg) do
    children = [
      {Horde.Registry, name: registry_name(sworm), keys: :unique},
      {Horde.DynamicSupervisor, name: supervisor_name(sworm), strategy: :one_for_one, children: []},
      {Sworm.Manager, arg}
    ]

    # register myself in the Sworm Directory
    Horde.Registry.register(Sworm.Directory, {sworm, node()}, nil)

    Supervisor.init(children, strategy: :one_for_all)
  end
end
