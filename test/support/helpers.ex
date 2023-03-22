defmodule Sworm.Support.Helpers do
  defmacro sworm_scenario(sworm, title, opts \\ [], do: block) do
    opts = Keyword.merge([cluster_size: 2, boot_timeout: 20_000], opts)

    quote do
      scenario unquote(title), unquote(opts) do
        node_setup do
          {:ok, _} = Application.ensure_all_started(:sworm)
          mod = unquote(sworm)

          case unquote(sworm) do
            nil ->
              :ok

            {m, f, a} ->
              {:ok, pid} = apply(m, f, a)
              Process.unlink(pid)

            mod ->
              opts = [delta_crdt_options: [sync_interval: 50]]
              {:ok, pid} = mod.start_link(opts)
              Process.unlink(pid)
          end

          :ok
        end

        unquote(block)
      end
    end
  end

  def wait_until(condition, timeout \\ 5_000) do
    result = condition.()

    cond do
      result ->
        result

      timeout <= 0 ->
        ExUnit.Assertions.flunk("Timeout reached waiting for condition")

      true ->
        Process.sleep(50)
        wait_until(condition, timeout - 50)
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
