require GenObject

GenObject.definterface Queue do
  defcallback(enqueue(queue, item))
  defcallback(dequeue(queue))

  def to_list(queue) do
    case dequeue(queue) do
      {:empty, _} ->
        []

      {value, rest} ->
        [value | to_list(rest)]
    end
  end

  def concat(q1, q2) do
    case dequeue(q2) do
      {:empty, _} -> q1
      {item, q} -> concat(enqueue(q1, item), q)
    end
  end

  defmodule Case do
    use ExUnit.CaseTemplate

    using opts do
      subject = Keyword.fetch!(opts, :subject)

      quote do
        defp subject do
          unquote(subject)
        end

        test "concat" do
          q1 = subject() |> Queue.enqueue(1) |> Queue.enqueue(2)
          q2 = subject() |> Queue.enqueue(3) |> Queue.enqueue(4)

          assert q1
                 |> Queue.concat(q2)
                 |> Queue.to_list() ==
                   [1, 2, 3, 4]
        end

        describe "enqueue |> dequeue" do
          test "first in first out" do
            q1 = subject() |> Queue.enqueue(1) |> Queue.enqueue(2)
            assert {1, q2} = Queue.dequeue(q1)
            assert {2, q3} = Queue.dequeue(q2)
            assert {:empty, ^q3} = Queue.dequeue(q3)
          end
        end

        describe "enqueue |> to_list" do
          test "first in first out" do
            assert subject()
                   |> Queue.enqueue(1)
                   |> Queue.enqueue(2)
                   |> Queue.enqueue(3)
                   |> Queue.enqueue(4)
                   |> Queue.to_list() == [1, 2, 3, 4]
          end
        end
      end
    end
  end
end

defmodule ErlQueue do
  use GenObject, implements: [Queue]

  def initialize() do
    :queue.new()
  end

  def enqueue(deconstruct(state), item) do
    construct(:queue.in(item, state))
  end

  def dequeue(deconstruct(state)) do
    case :queue.out(state) do
      {{:value, item}, new_state} ->
        {item, construct(new_state)}

      {:empty, new_state} ->
        {:empty, construct(new_state)}
    end
  end
end

defmodule ListQueue do
  use GenObject, implements: [Queue, Access, Enumerable]

  def count(deconstruct(state)) do
    {:ok, length(state)}
  end

  def fetch(queue, 0) do
    {item, _} = dequeue(queue)
    {:ok, item}
  end

  def fetch(queue, n) do
    {_item, rest} = dequeue(queue)
    fetch(rest, n - 1)
  end

  def initialize() do
    []
  end

  def enqueue(deconstruct(state), item) do
    construct(state ++ [item])
  end

  def dequeue(deconstruct([]) = this) do
    {:empty, this}
  end

  def dequeue(deconstruct([item | rest])) do
    {item, construct(rest)}
  end
end
