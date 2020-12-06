defmodule PiperTest do
  use ExUnit.Case

  alias Piper.{Step, Fact}

  defmodule TextProcessing do
    def tokenize(text) do
      text
      |> String.downcase()
      |> String.split(~R/[^[:alnum:]\-]/u, trim: true)
    end

    def count_words(list_of_words) do
      list_of_words
      |> Enum.reduce(Map.new(), fn word, map ->
        Map.update(map, word, 1, &(&1 + 1))
      end)
    end

    def count_uniques(word_count) do
      Enum.count(word_count)
    end

    def first_word(list_of_words) do
      List.first(list_of_words)
    end

    def last_word(list_of_words) do
      List.last(list_of_words)
    end
  end

  describe "construction" do
    test "Piper.new/1 builds a new dataflow graph for a given name with a root node" do
      test_flow = Piper.new("test flow")

      assert match?(%Graph{}, test_flow.flow)
      assert Graph.vertices(test_flow.flow) == [:root]
      assert test_flow.name == "test flow"
    end

    test "Piper.add_step/2 adds steps to the root node" do
      tokenize = Step.new(name: "tokenize", work: &TextProcessing.tokenize/1)

      pipeline =
        Piper.new("basic text processing example")
        |> Piper.add_step(tokenize)

      assert Graph.num_vertices(pipeline.flow) == 2
      assert Graph.vertices(pipeline.flow) |> hd() == :root
      assert Graph.vertices(pipeline.flow) |> List.last() == tokenize
    end

    test "Piper.add_step/2 can also accept step params" do
      pipeline =
        Piper.new("basic text processing example")
        |> Piper.add_step(name: "tokenize", work: &TextProcessing.tokenize/1)

      assert Graph.num_vertices(pipeline.flow) == 2
      assert Enum.member?(Graph.vertices(pipeline.flow), :root)
    end

    test "Piper.add_step/3 adds a dependent step to other steps" do
      first_word_step = Step.new(name: "first word", work: &TextProcessing.first_word/1)

      pipeline =
        Piper.new("basic text processing example")
        |> Piper.add_step(name: "tokenize", work: &TextProcessing.tokenize/1)
        |> Piper.add_step("tokenize", first_word_step)

      assert Graph.num_vertices(pipeline.flow) == 3
      assert Enum.member?(Graph.vertices(pipeline.flow), :root)
      assert Enum.member?(Graph.vertices(pipeline.flow), first_word_step)
    end

    test "Piper.add_step/3 can accept step params as the third argument" do
      pipeline =
        Piper.new("basic text processing example")
        |> Piper.add_step(name: "tokenize", work: &TextProcessing.tokenize/1)
        |> Piper.add_step("tokenize", name: "first word", work: &TextProcessing.first_word/1)

      steps = Graph.vertices(pipeline.flow)

      assert Graph.num_vertices(pipeline.flow) == 3

      assert Enum.member?(
               steps,
               Enum.find(steps, fn
                 :root -> false
                 step -> step.name == "first word"
               end)
             )
    end
  end

  describe "evaluation" do
    setup [:setup_basic_text_processing_pipeline]

    test "Piper.next_runnables/2 can accept a raw input and return a list of 'runnables'", %{
      text_processing_pipeline: text_processing_pipeline
    } do
      runnables = Piper.next_runnables(text_processing_pipeline, "anybody want a peanut?")
      assert Enum.count(runnables) == 1
      assert is_list(runnables)
    end

    test "Piper.run/1 can run a runnable returned from Piper.next_runnables/2", %{
      text_processing_pipeline: text_processing_pipeline
    } do
      runnables = Piper.next_runnables(text_processing_pipeline, "anybody want a peanut?")
      results = Enum.map(runnables, &Piper.run/1)
      assert match?([%Fact{value: ["anybody", "want", "a", "peanut"]}], results)
    end

    test "Dependent steps return next_runnables when fed facts they're dependent on", %{
      text_processing_pipeline: text_processing_pipeline
    } do
      initial_runnables = Piper.next_runnables(text_processing_pipeline, "anybody want a peanut?")

      [tokenized_result_fact | _] = Enum.map(initial_runnables, &Piper.run/1)

      dependent_to_tokenized_step_runnables =
        Piper.next_runnables(text_processing_pipeline, tokenized_result_fact)

      assert Enum.count(dependent_to_tokenized_step_runnables) == 3
    end
  end

  defp setup_basic_text_processing_pipeline(_context) do
    text_processing_pipeline =
      Piper.new("basic text processing example")
      |> Piper.add_step(name: "tokenize", work: &TextProcessing.tokenize/1)
      |> Piper.add_step("tokenize", name: "count words", work: &TextProcessing.count_words/1)
      |> Piper.add_step("count words",
        name: "count uniques",
        work: &TextProcessing.count_uniques/1
      )
      |> Piper.add_step("tokenize", name: "first word", work: &TextProcessing.first_word/1)
      |> Piper.add_step("tokenize", name: "last word", work: &TextProcessing.last_word/1)

    {:ok,
     [
       text_processing_pipeline: text_processing_pipeline
     ]}
  end
end
