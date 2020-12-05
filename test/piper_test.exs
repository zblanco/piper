defmodule PiperTest do
  use ExUnit.Case
  doctest Piper

  test "greets the world" do
    assert Piper.hello() == :world
  end
end
