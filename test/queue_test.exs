defmodule Queue do
  @callback initialize(opts :: keyword()) :: any()
  @callback enqueue(internal :: any(), item :: any()) :: any()
  @callback dequeue(internal :: any()) :: {any(), any()}

  def new(queue_mod, opts \\ []) do
    {queue_mod, apply(queue_mod, :initialize, opts)}
  end

  def enqueue({queue_mod, state}, item) do
    {queue_mod, queue_mod.enqueue(state, item)}
  end

  def dequeue({queue_mod, state}) do
    {new_state, item} = queue_mod.dequeue(state)
    {{queue_mod, new_state}, item}
  end

  # term "first in first out", %{queue_mod: queue_mod} do
  #   q1 = queue_mod |> Queue.new() |> Queue.enqueue(1) |> Queue.enqueue(2)
  #   assert {q2, 1} = Queue.dequeue(q1)
  #   assert {q3, 2} = Queue.dequeue(q2)
  #   assert {:empty, ^q3} = Queue.dequeue(q3)
  # end
end

defmodule ErlQueue do
  # defimplementation Queue do
  def initialize() do
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

  # end
end

defmodule ListQueue do
  # defimplementation Queue do
  def initialize() do
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

  # end
end

# then `defimplementation` would check if all the callbacks are defined
# also expand all the `terms` into `tests`

defmodule ErlQueueTest do
  use ExUnit.Case, asnyc: true

  test "first in first out" do
    q1 = ErlQueue |> Queue.new() |> Queue.enqueue(1) |> Queue.enqueue(2)
    assert {q2, 1} = Queue.dequeue(q1)
    assert {q3, 2} = Queue.dequeue(q2)
    assert {^q3, :empty} = Queue.dequeue(q3)
  end
end

defmodule ListQueueTest do
  use ExUnit.Case, asnyc: true

  test "first in first out" do
    q1 = ListQueue |> Queue.new() |> Queue.enqueue(1) |> Queue.enqueue(2)
    assert {q2, 1} = Queue.dequeue(q1)
    assert {q3, 2} = Queue.dequeue(q2)
    assert {^q3, :empty} = Queue.dequeue(q3)
  end
end
