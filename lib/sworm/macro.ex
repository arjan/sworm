defmodule Sworm.Macro do
  @moduledoc false

  def using(opts) do
    (Sworm.__info__(:functions)
     |> Enum.map(fn {name, arity} ->
       args = make_args(arity - 1)

       quote do
         def unquote(name)(unquote_splicing(args)) do
           apply(Sworm.Main, unquote(name), [__MODULE__, unquote_splicing(args)])
         end
       end
     end)) ++
      [
        quote do
          def configure do
            Application.put_env(:sworm, __MODULE__, unquote(opts))

            :ok
          end

          @on_load :configure
        end
      ]
  end

  defp make_args(0), do: []
  defp make_args(arity), do: 1..arity |> Enum.map(fn n -> Macro.var(:"arg#{n}", nil) end)
end
