defmodule FirewallPlugTest do
  use ExUnit.Case
  doctest FirewallPlug

  test "greets the world" do
    assert FirewallPlug.hello() == :world
  end
end
