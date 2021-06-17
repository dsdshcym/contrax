defcontract Queue do
  @callback new() :: t()
  @callback enqueue(t(), any()) :: t()
  @callback dequeue(t()) :: {t(), any()}

  term "first in first out" do
    q1 = new() |> enqueue(1) |> enqueue(2)
    assert {q2, 1} = dequeue(q1)
    assert {q3, 2} = dequeue(q2)
    assert {:empty, ^q3} = dequeue(q3)
  end
end

defmodule ErlQueue do
  defimplementation Queue do
    def new() do
      :queue.new()
    end

    def enqueue(q, item) do
      :queue.in(item, q)
    end

    def dequeue(q) do
      case :queue.out(q) do
        {{:value, item}, qq} ->
          {qq, item}

        {:empty, qq} ->
          {qq, :empty}
      end
    end
  end
end

defmodule ListQueue do
  defimplementation Queue do
    def new() do
      []
    end

    def enqueue(q, item) do
      q ++ [item]
    end

    def dequeue(q) do
      case q do
        [item | rest] ->
          {rest, item}

        [] ->
          {q, :empty}
      end
    end
  end
end

# then `defimplementation` would check if all the callbacks are defined
# also expand all the `terms` into `tests`

describe "ErlQueue" do
  import Contrax.ErlQueue

  test "first in first out" do
    q1 = new() |> enqueue(1) |> enqueue(2)
    assert {q2, 1} = dequeue(q1)
    assert {q3, 2} = dequeue(q2)
    assert {^q3, :empty} = dequeue(q3)
  end
end

describe "ListQueue" do
  import Contrax.ListQueue

  test "first in first out" do
    q1 = new() |> enqueue(1) |> enqueue(2)
    assert {q2, 1} = dequeue(q1)
    assert {q3, 2} = dequeue(q2)
    assert {^q3, :empty} = dequeue(q3)
  end
end
