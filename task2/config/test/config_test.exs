defmodule ConfigTest do
  use ExUnit.Case
  doctest Config

  setup do
    Config.start("test/examples/sample.toml")
    on_exit fn -> Config.stop end
  end

  test "get config option" do
    assert Config.get(:title) == "TOML Example"
    assert Config.get([:database, :server]) == "192.168.1.1"
    assert Config.get([:servers, :alpha, :ip]) == "10.0.0.1"
  end

  test "set config option" do
    # given
    assert Config.get(:title) == "TOML Example"
    assert Config.get([:servers, :alpha, :ip]) == "10.0.0.1"
    # when
    Config.set(:title, "New title")
    Config.set([:servers, :alpha, :ip], "10.0.0.10")
    # then
    assert Config.get(:title) == "New title"
    assert Config.get([:servers, :alpha, :ip]) == "10.0.0.10"
  end

end
