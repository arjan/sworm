defmodule SwormTest do
  use ExUnit.Case
  doctest Sworm

  test "supervisor" do
    {:ok, pid} = Sworm.Supervisor.start_link({Foo, []})
  end
end
