defmodule Sworm.Application do
  @moduledoc false

  use Application

  @env Mix.env()

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Sworm.Supervisor]
    Supervisor.start_link(children(@env), opts)
  end

  if @env == :test do
    defp children(:test) do
      children(:prod) ++ [HandoffSworm]
    end
  end

  defp children(_) do
    [
      {Horde.Registry, name: Sworm.Directory, keys: :unique},
      Sworm.DirectoryManager
    ]
  end
end
