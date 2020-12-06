defmodule Piper.Runner do
  @moduledoc """
  Behavior defining what a Piper Runner must implement.

  A Piper Runner is simply any module which knows how to execute `Piper.run/1` for a given runnable
    in an arbitrary runtime execution context.

  As every runnable returned by `Piper.next_runnables/2` is able to run in parallel a Piper.Runner
    may choose how it wants to optimize that workload as it sees fit.

  ## Example

  ```
  defmodule MyApp.TaskAsyncRunner do
    @behaviour Piper.Runner

    @impl true
    def run(runnable) when is_tuple(runnable) do
      run([runnable])
    end

    def run(runnables) when is_list(runnables) do
      runnables
      |> Enum.map(fn runnable ->
        Task.async(fn ->
          result = Piper.run(runnable)
          MyPubSub.publish(:jobs, result)
        end)
      end)
      |> Task.await_many()

      :ok
    end
  end
  ```
  """
  @callback run(Piper.runnable() | list(Piper.runnable())) :: :ok
end
