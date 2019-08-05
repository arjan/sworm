defmodule Sworm.Util do
  @moduledoc false

  def registry_name(sworm), do: Module.concat(sworm, "Registry")
  def supervisor_name(sworm), do: Module.concat(sworm, "Supervisor")
  def manager_name(sworm), do: Module.concat(sworm, "Manager")

  def get_sworm_config(sworm, key, default) do
    Application.get_env(:sworm, sworm, [])
    |> Keyword.get(key, default)
  end
end
