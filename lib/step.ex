defmodule Piper.Step do
  defstruct ~w(
    name
    work
  )a

  @type t() :: %__MODULE__{
    name: binary(),
    work: function() | mfa()
  }

  @spec new(list) :: __MODULE__.t()
  def new(params) when is_list(params) do
    struct!(__MODULE__, params)
  end
end
