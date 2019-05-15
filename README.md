# Sworm

[![Build Status](https://travis-ci.org/arjan/sworm.svg?branch=master)](https://travis-ci.org/arjan/sworm)

A combination of a global, distributed process registry and
supervisor, rolled into one, friendly API.

This library aims to be a drop-in replacement for
[Swarm](https://github.com/bitwalker/swarm), but it is built on top of
[Horde](https://github.com/derekkraan/horde).


Sworms can be defined using a macro and then added to your supervision
tree.

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
