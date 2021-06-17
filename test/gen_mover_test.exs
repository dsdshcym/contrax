GenObject.definterface GenMover do
  def fire: run(mover, source, destination)
end

defmodule ConcatMover do
  use GenObject

  def initialize(m1, m2) do
    [m1, m2]
  end

  implement GenMover do
    def run([m1, m2], source, destination) do
      with :ok <- GenMover.run(m1, source, destination),
           :ok <- GenMover.run(m2, source, destination) do
        :ok
      end
    end
  end
end

defmodule OKMover do
  def initialize() do
    __MODULE__
  end

  def handle_fire(__MODULE__, {:run, _source, _destination}) do
    :ok
  end
end

defmodule ErrorMover do
  def initialize(error) do
    error
  end

  def handle_fire(error, {:run, _source, _destination}) do
    {:error, error}
  end
end

defmodule ConcatMoverTest do
  use ExUnit.Case, async: true

  test "calls movers one by one" do
    mover =
      GenObject.new(ConcatMover, [
        GenObject.new(OKMover),
        GenObject.new(OKMover)
      ])

    assert :ok = GenMover.run(mover, :source, :destination)
  end

  test "returns the first error it encounters" do
    mover =
      GenObject.new(ConcatMover, [
        GenObject.new(ErrorMover, ["first"]),
        GenObject.new(ErrorMover, ["second"])
      ])

    assert {:error, "first"} = GenMover.run(mover, :source, :destination)

    mover =
      GenObject.new(ConcatMover, [
        GenObject.new(OKMover),
        GenObject.new(ErrorMover, ["first"])
      ])

    assert {:error, "first"} = GenMover.run(mover, :source, :destination)
  end

  test "does not call second mover when first returns an error" do
    mover =
      GenObject.new(ConcatMover, [
        GenObject.new(ErrorMover, ["first"]),
        fn :source, :destination -> raise("second mover should not be called") end
      ])

    assert {:error, "first"} = GenMover.run(mover, :source, :destination)
  end
end
