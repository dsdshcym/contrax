require GenObject

GenObject.definterface GenMover do
  defcallback(run(mover, source, destination))
end

defmodule ConcatMover do
  use GenObject, implements: [GenMover]

  def initialize(m1, m2) do
    [m1, m2]
  end

  def run(matcho([m1, m2]), source, destination) do
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

  def run(matcho(OKMover), _source, _destination) do
    :ok
  end
end

defmodule ErrorMover do
  use GenObject, implements: [GenMover]

  def initialize(error) do
    error
  end

  def run(matcho(error), _source, _destination) do
    {:error, error}
  end
end
