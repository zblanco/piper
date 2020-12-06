defmodule Piper.Fact do
  defstruct ~w(
    value
    runnable
  )a

  @type t() :: %__MODULE__{
    value: term(),
    runnable: Piper.runnable() | nil
  }
end
