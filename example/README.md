# Sworm Example

This example creates an `Example.Swarm` and adds it to the applications' supervision tree.

From now on, you can call `Swarm` functions as usual on this

```
iex> Example.Swarm.register_name("foo", Example.Worker, :start_link, [])
{:ok, #PID<0.603.0>}
iex> Example.Swarm.register_name("bar", Example.Worker, :start_link, [])
{:ok, #PID<17229.814.0>}
iex> Example.Swarm.registered
[
  {"foo", #PID<0.603.0>},
  {"bar", #PID<17229.814.0>>}
]
```

## Running in a cluster

The `start.sh` script lets you start a test cluster

`./start.sh a` -> starts `a@127.0.0.1` node, etc.

You still need to manually connect the nodes using something like `Node.ping :"b@127.0.0.1"`

The Example.Swarm automatically distributes itself over the cluster,
so when using `register_name` you see the processes on all nodes, and
you see local and remote processes mixed when calling
`Example.Swarm.registered()`.
