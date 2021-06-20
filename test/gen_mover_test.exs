defmodule ConcatMoverTest do
  use ExUnit.Case, async: true

  test "calls movers one by one" do
    mover =
      ConcatMover.new(
        OKMover.new(),
        OKMover.new()
      )

    assert :ok = GenMover.run(mover, :source, :destination)
  end

  test "returns the first error it encounters" do
    mover =
      ConcatMover.new(
        ErrorMover.new("first"),
        ErrorMover.new("second")
      )

    assert {:error, "first"} = GenMover.run(mover, :source, :destination)

    mover =
      ConcatMover.new(
        OKMover.new(),
        ErrorMover.new("first")
      )

    assert {:error, "first"} = GenMover.run(mover, :source, :destination)
  end

  test "does not call second mover when first returns an error" do
    mover =
      ConcatMover.new(
        ErrorMover.new("first"),
        fn :source, :destination -> raise("second mover should not be called") end
      )

    assert {:error, "first"} = GenMover.run(mover, :source, :destination)
  end
end
