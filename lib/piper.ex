defmodule Piper do
  @moduledoc """
  A minimal DAG (Directed Acyclic Graph) structure for modeling static dataflow dependency pipelines.

  While this works, it's limited to static input-output Step dependencies.

  This means it cannot express conditional logic or complex control flow unlike
  more complex forward chaining implementations like RETE.

  However Piper is sufficient for many simple parallelizeable job pipelines such as
    in Natural Language Processing where one might want to modify and model the pipeline at runtime.
  """
  alias Piper.{Fact, Step}

  @type runnable() :: {Step.t(), Fact.t()}

  @type t() :: %__MODULE__{
          name: binary(),
          flow: Graph.t()
        }

  defstruct ~w(
    name
    flow
  )a

  @spec new(name :: binary()) :: Piper.t()
  @doc """
  Builds a new Piper struct with the given name.
  """
  def new(name) when is_binary(name) do
    %__MODULE__{
      name: name,
      flow: Graph.new() |> Graph.add_vertex(:root)
    }
  end

  @doc """
  Runs a given runnable to produce a new fact.
  """
  def run({%Step{work: work} = step, %Fact{value: value} = fact}) do
    result = execute(work, value)

    %Fact{
      value: result,
      runnable: {step, fact}
    }
  end

  defp execute({m, f, 1}, value), do: apply(m, f, [value])

  defp execute(work, value) when is_function(work, 1), do: work.(value)

  @spec next_runnables(Piper.t(), Piper.Fact.t()) :: [{Step.t(), Fact.t()}]
  @doc """
  Returns a list of the next runnables in the Piper pipeline for a given fact.
  """
  def next_runnables(
        %__MODULE__{flow: flow},
        %Fact{runnable: {%Step{} = parent_step, _parent_fact}} = fact
      ) do
    next_steps = Graph.out_neighbors(flow, parent_step)

    Enum.map(next_steps, fn step ->
      {step, Map.delete(fact, :runnable)}
    end)
  end

  def next_runnables(
        %__MODULE__{flow: flow},
        %Fact{runnable: nil} = fact
      ) do
    next_steps = Graph.out_neighbors(flow, :root)

    Enum.map(next_steps, fn step ->
      {step, fact}
    end)
  end

  def next_runnables(
        %__MODULE__{} = piper,
        raw_fact
      ),
      do: next_runnables(piper, %Fact{value: raw_fact})

  @spec add_step(Piper.t(), Piper.Step.t() | keyword()) :: Piper.t()
  @doc """
  Adds a step connected directly to the root of the Piper graph.

  This means the given step will always produce a runnable when next_runnables/2 is called with a raw fact.
  """
  def add_step(%__MODULE__{flow: flow} = piper, %Step{} = step) do
    %__MODULE__{
      piper
      | flow:
          flow
          |> Graph.add_vertex(step)
          |> Graph.add_edge(:root, step, label: {:root, step.name})
    }
  end

  def add_step(%__MODULE__{} = piper, step_params) when is_list(step_params) do
    add_step(piper, Step.new(step_params))
  end

  @spec add_step(
          Piper.t(),
          parent_step_name :: binary() | Piper.Step.t(),
          child_step_params :: [] | Piper.Step.t()
        ) :: Piper.t()
  def add_step(%__MODULE__{flow: flow} = piper, parent_step_name, %Step{} = child_step)
      when is_binary(parent_step_name) do
    parent_step = get_step_by_name(flow, parent_step_name)
    add_step(piper, parent_step, child_step)
  end

  def add_step(%__MODULE__{flow: flow} = piper, %Step{} = parent_step, %Step{} = child_step) do
    %__MODULE__{
      piper
      | flow:
          flow
          |> Graph.add_vertex(child_step, child_step.name)
          |> Graph.add_edge(parent_step, child_step, label: {parent_step.name, child_step.name})
    }
  end

  def add_step(piper, parent_step_name, child_step_params)
      when is_binary(parent_step_name) and is_list(child_step_params) do
    add_step(piper, parent_step_name, Step.new(child_step_params))
  end

  defp get_step_by_name(flow, name) do
    Enum.find(Graph.vertices(flow), nil, fn
      %Step{name: step_name} -> step_name == name
      :root -> false
    end)
  end
end
