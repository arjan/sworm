defmodule Sworm do
  @moduledoc """
  Sworm takes the accessible API from
  [Swarm](https://github.com/bitwalker/swarm), and combines it with
  the robustness of [Horde](https://github.com/derekkraan/horde).

  It strives to be a combination of a global, distributed process
  registry and supervisor, accessible through a friendly API.

  ## Usage

  The concept behind Sworm is that there can be multiple, distinct
  "sworms" living inside a cluster of BEAM nodes. To define a Sworm,
  you define a module like this:

      defmodule MyProcesses do
        use Sworm
      end

  Now, the `MyProcesses` module must be added to your application's supervison tree.

  When you now start the application, you can use the functions from
  the `Sworm` module inside your `MyProcesses` module:

      {:ok, pid} = MyProcesses.register_name("my worker", MyWorker, :start_link, [arg1, arg2])


  """

  alias Sworm.Main

  @doc """
  Create a child specification for adding a new Sworm to the supervisor tree.
  """
  @spec child_spec(sworm :: atom(), opts :: [term()]) :: Supervisor.child_spec()
  defdelegate child_spec(sworm, opts \\ []), to: Main

  @doc """
  Start and link a Sworm in a standalone fashion.

  > You almost will never need this function, as it is more usual to
  > start a Sworm directly in a supervisor tree, using the provided
  > child_spec function.
  """
  @spec start_link(sworm :: atom(), opts :: [term()]) :: {:ok, pid()}
  defdelegate start_link(sworm, opts \\ []), to: Main

  @doc """
  Register a name in the given Sworm. This function takes a
  module/function/args triplet, and starts the process, registers the
  pid with the given name, and handles cluster topology changes by
  restarting the process on its new node using the given MFA.

  Processes that are started this way are added to the Sworm's dynamic
  Horde supervisor, distributed over the members of the Horde
  according to its cluster strategy, and restarted when they crash.

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
  Registers the given name to the given process. Names
  registered this way will not be shifted when the cluster
  topology changes, and are not restarted by Sworm.

  If no pid is given, `self()` is used for the registration.
  """
  @spec register_name(sworm :: atom(), name :: term(), pid :: pid()) :: :yes | :no
  defdelegate register_name(sworm, name, pid \\ self()), to: Main

  @doc """
  Either finds the named process in the sworm or registers it using
  the ``register/4`` function.
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

  @doc """
  Joins a process to a group.

  Returns an error when the given process is not part of the sworm.
  """
  @spec join(sworm :: atom(), term(), pid()) :: :ok | {:error, :no_sworm}
  defdelegate join(sworm, group, pid \\ self()), to: Main

  @doc """
  Removes a process from a group

  Returns an error when the given process is not part of the sworm.
  """
  @spec leave(sworm :: atom(), term(), pid()) :: :ok
  defdelegate leave(sworm, group, pid \\ self()), to: Main

  @doc """
  Gets all the members of a group within the sworm.

  Returns a list of pids.
  """
  @spec members(sworm :: atom(), term()) :: [pid]
  defdelegate members(sworm, group), to: Main

  defmacro __using__(opts), do: Sworm.Macro.using(opts)
end
