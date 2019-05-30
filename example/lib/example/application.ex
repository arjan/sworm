defmodule Example.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      Example.Swarm
    ]

    spawn(fn ->
      Process.sleep(2000)
      Node.ping(:"a@127.0.0.1")
      Node.ping(:"b@127.0.0.1")
      Node.ping(:"c@127.0.0.1")
    end)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Example.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
