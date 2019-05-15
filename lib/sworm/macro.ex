defmodule Sworm.Macro do
  @moduledoc false

  @public_api [
    child_spec: 1,
    register_name: 4,
    whereis_or_register_name: 4,
    unregister_name: 1,
    whereis_name: 1,
    registered: 0
  ]

  def using(_opts) do
    @public_api
    |> Enum.map(fn {name, arity} ->
      args = make_args(arity)

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
