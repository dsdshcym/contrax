defmodule ContraxTest do
  use ExUnit.Case
  doctest Contrax

  test "greets the world" do
    assert Contrax.hello() == :world
  end
end
