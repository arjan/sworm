defmodule Sworm do
  @moduledoc """
  Documentation for Sworm.

  Sworm takes the API from
  [Swarm](https://github.com/bitwalker/swarm), and combines it with
  the robustness of [Horde](https://github.com/derekkraan/horde).

  """

  @doc """
  Create a child specification for adding a new Sworm to the supervisor tree.
  """
  @spec child_spec(sworm :: atom(), opts :: [term()]) :: Supervisor.child_spec()
  defdelegate child_spec(sworm, opts \\ []), to: Main

  alias Sworm.Main

  @doc """
  Register a name in the given Sworm. This function takes a
  module/function/args triplet, and starts the process, registers the
  pid with the given name, and handles cluster topology changes by
  restarting the process on its new node using the given MFA.
  """
  @spec register_name(
          sworm :: atom(),
          name :: term(),
          module :: atom(),
          function :: atom(),
          args :: [term]
        ) :: {:ok, pid} | {:error, term}
  defdelegate register_name(sworm, name, m, f, a), to: Main

  @doc """
   Either finds the named process in the sworm or registers it using the register function.
  """
  @spec whereis_or_register_name(
          sworm :: atom(),
          name :: term(),
          module :: atom(),
          function :: atom(),
          args :: [term]
        ) :: {:ok, pid()} | {:error, term()}
  defdelegate whereis_or_register_name(sworm, name, m, f, a), to: Main

  @doc """
  Unregisters the given name from the sworm.
  """
  @spec unregister_name(sworm :: atom(), name :: term()) :: :ok
  defdelegate unregister_name(sworm, name), to: Main

  @doc """
  Get the pid of a registered name within a sworm.
  """
  @spec whereis_name(sworm :: atom(), name :: term()) :: pid() | nil
  defdelegate whereis_name(sworm, name), to: Main

  @doc """
  Gets a list of all registered names and their pids within a sworm
  """
  @spec registered(sworm :: atom()) :: [{name :: term(), pid()}]
  defdelegate registered(sworm), to: Main
end
