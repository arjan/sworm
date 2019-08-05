# Sworm

[![Build Status](https://travis-ci.org/arjan/sworm.svg?branch=master)](https://travis-ci.org/arjan/sworm)
[![Hex pm](http://img.shields.io/hexpm/v/sworm.svg?style=flat)](https://hex.pm/packages/sworm)
[![Hex.pm](https://img.shields.io/hexpm/l/sworm.svg)](https://hex.pm/packages/sworm)

A combination of a global, distributed process registry and
supervisor, rolled into one, friendly API.

This library aims to be a drop-in replacement for
[Swarm](https://github.com/bitwalker/swarm), but it is built on top of
[Horde](https://github.com/derekkraan/horde).

## Usage

Sworms can be defined using a macro and then added to your supervision
tree. To replicate Swarm, create the following module:

```elixir
defmodule Swarm do
  use Sworm
end
```

You are not entirely done yet! Unlike the original Swarm, which has a
"singleton" process tree, you will need to add each `Sworm` to your
own application's supervision tree:


```elixir
    children = [
      Swarm,
      ...
    ]
```

Now you can call `Swarm.registered()`, `Swarm.register_name` etc like you're used to.

> Note: handoff still needs to be implemented, see issue #1.


## Architecture

Sworm combines Horde's DynamicSupervisor and Registry modules to
reproduce the Swarm library.

To be able to register an aribtrary `{m, f, a}` specification with
Sworm, it spawns a *delegate process* and uses this process as the
primary process for name registration and supervision. This delegate
process then spawns and links the actual process as specified in the
MFA.

This way, any MFA can be used with Sworm like it can with Swarm, and
does not need to be aware of it, because the delegate process handles
name registration, process shutdown on name conflicts, and, in the
near future, process handoff.


## Node affinity / node black-/whitelisting

Contrarily to Swarm, Sworm does not have a black- or whitelisting
mechanism.  By design, each Sworm in the cluster only distributes
processes among those nodes that explicitly have that particular sworm
started in its supervision tree.

Sworm maintains a cluster-global directory CRDT of registered Sworms,
keeping track of on which node which type(s) of Sworm run.

This ensures that processes are only started through Sworm on nodes
that the sworm itself is also running on, instead of assuming that the
cluster is homogenous and processes can run on each node, like Swarm
does.


## Process state handoff

Each individual Sworm can be configured to perform state a handoff to
transition the state of the process.

The case here is that when a node shuts down, Sworm will move the
processes running on that node onto one of the other nodes of the
cluster. By default, these processes are started with a clean sheet,
e.g., the state of the process is lost. But when the Sworm is
configured to perform process handoffs, the processes in the sworm are
given some time to hand off their state into the cluster, so that the
state can be restored right after the process is started again on
another node.

> Process handoff in Sworm works differently from the Swarm library.

Process handoff must be explicitly enabled per sworm:

```elixir
defmodule MyProcesses do
  use Sworm, handoff: true
end
```

Or, in `config.exs`:

```elixir
config :sworm, MyProcesses, handoff: true
```

When a handoff occurs, the process that is about to exit, receives the
following message:

    {MyProcesses, :begin_handoff, delegate, ref}

If it wants to pass on its internal state it needs to send the
delegate a corresponding ack:

    send(delegate, {ref, :handoff_state, some_state})

Now, on the other node, the new process will be started in the normal
way, however, right after it is started it will receive the
`:end_handoff` signal:

     {MyProcesses, :end_handoff, some_state}

It can then restore its state to the state that was sent by its
predecessor.

The most basic implementation in a genserver process of this flow is this:

```elixir
def handle_info({MyProcesses, :begin_handoff, delegate, ref}, state) do
  send(delegate, {ref, :handoff_state, state})
  {:noreply, state}
end

def handle_info({MyProcesses, :end_handoff, state}, _state) do
  {:noreply, state}
end
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `sworm` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sworm, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/sworm](https://hexdocs.pm/sworm).
