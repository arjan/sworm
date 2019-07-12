defmodule Sworm.Support.Helpers do
  def wait_until(condition, timeout \\ 5_000) do
    cond do
      condition.() ->
        :ok

      timeout <= 0 ->
        ExUnit.Assertions.flunk("Timeout reached waiting for condition")

      true ->
        Process.sleep(100)
        wait_until(condition, timeout - 100)
    end
  end
end
