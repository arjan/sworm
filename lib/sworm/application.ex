defmodule Sworm.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Horde.Registry, name: Sworm.Directory, keys: :unique},
      Sworm.DirectoryManager
    ]

    opts = [strategy: :one_for_one, name: Sworm.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
