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

    children = [
      {Horde.Registry, name: registry_name(sworm), keys: :unique},
      {Horde.DynamicSupervisor,
       name: supervisor_name(sworm),
       strategy: :one_for_one,
       children: [],
       distribution_strategy: distribution_strategy},
      {Sworm.Manager, arg}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
