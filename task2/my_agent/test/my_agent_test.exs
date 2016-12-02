defmodule MyAgentTest do
  use ExUnit.Case
  doctest MyAgent

  @tested GenAgent

  test "the truth" do
    assert 1 + 1 == 2
  end
end
