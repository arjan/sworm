defmodule Sworm.Main do
  def child_spec(sworm, opts) do
    %{
      id: sworm,
      start: {Sworm.Supervisor, :start_link, {sworm, opts}},
      restart: :permanent,
      shutdown: 5000,
      type: :supervisor
    }
  end
end
