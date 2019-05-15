defmodule Sworm.Supervisor do
  @moduledoc false
  @behaviour Supervisor

  import Sworm.Util

  def start_link(sworm, opts) do
    Supervisor.start_link(__MODULE__, {sworm, opts}, name: sworm)
  end

  @impl true
  def init({sworm, _opts} = arg) do
    children = [
      {Horde.Registry, name: registry_name(sworm), keys: :unique},
      {Horde.Supervisor, name: supervisor_name(sworm), strategy: :one_for_one, children: []},
      {Sworm.Manager, arg}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
