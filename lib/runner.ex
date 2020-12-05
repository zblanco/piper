defmodule Piper.Runner do
  @moduledoc """
  Behavior defining what a Piper Runner must implement.
  """
  @type runnables() :: list(tuple())

  @callback run(runnables()) :: :ok
end
