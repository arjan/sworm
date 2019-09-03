defmodule Example.Swarm do
  use Sworm, handoff: true, restart: :temporary
end
