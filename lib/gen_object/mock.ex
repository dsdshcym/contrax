defmodule GenObject.Mock do
  use GenObject

  defmacro defmock(for: protocol) do
    protocol_mod = Macro.expand(protocol, __CALLER__)

    mock_funs =
      for {fun, arity} <- protocol_mod.__protocol__(:functions) do
        args = Macro.generate_unique_arguments(arity - 1, __MODULE__)

        quote do
          def unquote(fun)(%GenObject.Mock.Object{state: promox} = this, unquote_splicing(args)) do
            unquote(protocol_mod).unquote(fun)(promox, unquote_splicing(args))
          end
        end
      end

    quote do
      require Promox
      Promox.defmock(for: unquote(protocol))

      defimpl unquote(protocol_mod), for: GenObject.Mock.Object do
        unquote(mock_funs)
      end
    end
  end

  def initialize() do
    Promox.new()
  end

  def expect(matcho(promox) = this, protocol, name, n \\ 1, code) do
    Promox.expect(promox, protocol, name, n, code)

    this
  end

  def stub(matcho(promox) = this, protocol, name, code) do
    Promox.stub(promox, protocol, name, code)

    this
  end

  def verify!(matcho(promox)) do
    Promox.verify!(promox)
  end
end
