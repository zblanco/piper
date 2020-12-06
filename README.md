# Piper

A minimal tool for building Dataflow graphs of dependent steps.

Uses a simple DAG (Directed Acyclic Graph) model for building a static 
  representation of dependencies between Steps. This is just a datastructure
  so it doesn't impose any runtime execution constraints. 

Piper was implemented for demonstration purposes, and as such is not published to Hex.

Feel free to fork, or vendor into your own project should you find this pattern useful.
  
## Usage

Any implementation of the `Piper.Runner` behaviour may execute the set of Runnables/Tasks/Jobs returned by the `Piper.next_runnables/2` function using `Piper.run/1` in a runtime context.

Any runnable returned by `next_runnables/2` is guaranteed to be parallelizeable in context
to other runnables so a `Piper.Runner` can safely dispatch these tasks to separate processes.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `piper` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:piper, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/piper](https://hexdocs.pm/piper).

