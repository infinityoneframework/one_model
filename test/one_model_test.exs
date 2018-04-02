defmodule OneModelTest do
  use ExUnit.Case
  doctest OneModel

  test "greets the world" do
    assert OneModel.hello() == :world
  end
end
