defmodule Sworm.Util do
  @moduledoc false

  def registry_name(sworm), do: Module.concat(sworm, "Registry")
  def supervisor_name(sworm), do: Module.concat(sworm, "Supervisor")
  def manager_name(sworm), do: Module.concat(sworm, "Manager")

  @global_blacklist [~r/^remsh.*$/, ~r/^.+_upgrader_.+$/, ~r/^.+_maint_.+$/]

  # Determine if a node should be ignored, even if connected
  # The whitelist and blacklist can contain literal strings, regexes, or regex strings
  # By default, all nodes are allowed, except those which are remote shell sessions
  # where the node name of the remote shell starts with `remsh` (relx, exrm, and distillery)
  # all use that prefix for remote shells.
  def ignore_node?(node, opts) do
    blacklist = Enum.uniq(@global_blacklist ++ (opts[:node_blacklist] || []))
    whitelist = opts[:node_whitelist] || []
    Sworm.RingUtils.ignore_node?(node, blacklist, whitelist)
  end
end
