defmodule Sworm.Macro do
  @moduledoc false

  def using(_opts) do
    Sworm.__info__(:functions)
    |> Enum.map(fn {name, arity} ->
      args = make_args(arity - 1)

      quote do
        def unquote(name)(unquote_splicing(args)) do
          apply(Sworm.Main, unquote(name), [__MODULE__, unquote_splicing(args)])
        end
      end
    end)
  end

  defp make_args(0), do: []
  defp make_args(arity), do: 1..arity |> Enum.map(fn n -> Macro.var(:"arg#{n}", nil) end)
end
