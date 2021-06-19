require GenObject

GenObject.definterface GenMover do
  def run(mover, source, destination)
end

defmodule ConcatMover do
  use GenObject, implements: [GenMover]

  def initialize(m1, m2) do
    [m1, m2]
  end

  def run(deconstruct([m1, m2]), source, destination) do
    with :ok <- GenMover.run(m1, source, destination),
         :ok <- GenMover.run(m2, source, destination) do
      :ok
    end
  end
end

defmodule OKMover do
  use GenObject, implements: [GenMover]

  def initialize() do
    __MODULE__
  end

  def run(deconstruct(OKMover), _source, _destination) do
    :ok
  end
end

defmodule ErrorMover do
  use GenObject, implements: [GenMover]

  def initialize(error) do
    error
  end

  def run(deconstruct(error), _source, _destination) do
    {:error, error}
  end
end

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
