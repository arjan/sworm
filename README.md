# Sworm

[![Build Status](https://travis-ci.org/arjan/sworm.svg?branch=master)](https://travis-ci.org/arjan/sworm)

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

You are not entirely done yet! Unlike the original Swarm, which has an
in-lirbary, "singleton" process tree, you will need to add each
`Sworm` to your own application's supervision tree:

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
