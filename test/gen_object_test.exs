require GenObject

GenObject.definterface Queue do
  def morph: enqueue(queue, item)

  def ask: dequeue(queue)

  defmodule Case do
    use ExUnit.CaseTemplate

    using opts do
      subject = Keyword.fetch!(opts, :subject)

      quote do
        test "first in first out" do
          q1 = unquote(subject) |> Queue.enqueue(1) |> Queue.enqueue(2)
          assert {1, q2} = Queue.dequeue(q1)
          assert {2, q3} = Queue.dequeue(q2)
          assert {:empty, ^q3} = Queue.dequeue(q3)
        end
      end
    end
  end
end

defmodule ErlQueue do
  use GenObject, implement: [Queue]

  # defimplementation Queue do
  def initialize() do
    :queue.new()
  end

  def enqueue(state, item) do
    :queue.in(item, state)
  end

  def dequeue(state) do
    case :queue.out(state) do
      {{:value, item}, new_state} ->
        {item, new_state}

      {:empty, new_state} ->
        {:empty, new_state}
    end
  end

  # end
end

defmodule ListQueue do
  # defimplementation Queue do

  use GenObject, implement: [Queue]

  def initialize() do
    []
  end

  def enqueue(state, item) do
    state ++ [item]
  end

  def dequeue(state) do
    case state do
      [item | rest] ->
        {item, rest}

      [] ->
        {:empty, state}
    end
  end

  # end
end

# then `defimplementation` would check if all the callbacks are defined
# also expand all the `terms` into `tests`

defmodule ErlQueueTest do
  use Queue.Case, async: true, subject: ErlQueue.new()
end

defmodule ListQueueTest do
  use Queue.Case, async: true, subject: ListQueue.new()
end
