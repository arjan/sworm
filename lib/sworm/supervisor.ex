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
    distribution_strategy =
      get_sworm_config(sworm, :distribution_strategy, Horde.UniformDistribution)

    delta_crdt_options = get_sworm_config(sworm, :delta_crdt_options, [])

    children = [
      {Horde.Registry,
       name: registry_name(sworm), keys: :unique, delta_crdt_options: delta_crdt_options},
      {Horde.DynamicSupervisor,
       name: supervisor_name(sworm),
       strategy: :one_for_one,
       children: [],
       delta_crdt_options: delta_crdt_options,
       distribution_strategy: distribution_strategy},
      {Sworm.Manager, arg}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
