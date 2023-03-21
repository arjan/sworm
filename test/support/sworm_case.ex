defmodule SwormCase do
  defmacro __using__(_) do
    quote do
      import SwormCase
      require Sworm.Support.Helpers
      import Sworm.Support.Helpers

      use ExUnit.ClusteredCase
    end
  end

  ###

  def sworm(name) do
    {:ok, pid} = Sworm.start_link(name)

    ExUnit.Callbacks.on_exit(fn ->
      Process.sleep(50)
      Process.exit(pid, :kill)
      Process.sleep(200)
    end)
  end

  def mailbox() do
    mailbox([])
  end

  def mailbox(acc) do
    receive do
      item -> mailbox([item | acc])
    after
      100 -> Enum.reverse(acc)
    end
  end
end
