defmodule ErlQueueTest do
  use Queue.Case, async: true, subject: ErlQueue.new()
end

defmodule ListQueueTest do
  use Queue.Case, async: true, subject: ListQueue.new()

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
