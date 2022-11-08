defmodule Sworm.Support.Helpers do
  defmacro sworm_scenario(sworm, title, size \\ 2, do: block) do
    quote do
      scenario unquote(title),
        cluster_size: unquote(size),
        boot_timeout: 20_000,
        stdout: :standard_error do
        node_setup do
          {:ok, _} = Application.ensure_all_started(:sworm)
          mod = unquote(sworm)

          if mod != nil do
            {:ok, pid} = mod.start_link()
            Process.unlink(pid)
          end

          :ok
        end

        unquote(block)
      end
    end
  end

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
