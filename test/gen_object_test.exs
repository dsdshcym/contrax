defmodule ErlQueueTest do
  use ExUnit.Case, async: true
  use GenObject.Case, for: Queue, subjects: [queue: ErlQueue.new()]
end

defmodule ListQueueTest do
  use ExUnit.Case, async: true
  use GenObject.Case, for: Queue, subjects: [queue: ListQueue.new()]

  test "get_in" do
    q = ListQueue.new() |> Queue.enqueue(1) |> Queue.enqueue(2)

    assert get_in(q, [0]) == 1
    assert get_in(q, [1]) == 2
  end

  test "Enum.count/1" do
    q = ListQueue.new() |> Queue.enqueue(1) |> Queue.enqueue(2)

    assert Enum.count(q) == 2
  end
end
