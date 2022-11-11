defmodule Sworm.Support.Helpers do
  defmacro sworm_scenario(sworm, title, size \\ 2, do: block) do
    opts = [cluster_size: size, boot_timeout: 20_000]

    quote do
      scenario unquote(title), unquote(opts) do
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

  defmacro until_match(a, b, timeout \\ 2500) do
    quote do
      Sworm.Support.Helpers.wait_until(
        fn ->
          match?(unquote(a), unquote(b))
        end,
        unquote(timeout)
      )

      unquote(b)
    end
  end
end
