defmodule SwormCase do
  defmacro __using__(_) do
    quote do
      require Sworm.Support.Helpers
      import Sworm.Support.Helpers

      use ExUnit.ClusteredCase
    end
  end
end
