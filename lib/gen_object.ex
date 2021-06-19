defmodule GenObject do
  defmacro __using__(opts) do
    interfaces = Keyword.get(opts, :implements, [])

    quote do
      import GenObject.Object, only: [deconstruct: 1]

      for interface <- unquote(interfaces) do
        @behaviour interface
      end

      defp construct(state) do
        GenObject.Object.build(__MODULE__, state)
      end

      @before_compile GenObject
    end
  end

  defmacro __before_compile__(env) do
    initializes =
      env.module
      |> Module.definitions_in(:def)
      |> Enum.filter(&match?({:initialize, _}, &1))

    # TODO: raise if cannot find any initialize/* functions

    for {:initialize, arity} <- initializes do
      args = Macro.generate_unique_arguments(arity, env.module)

      quote do
        def new(unquote_splicing(args)) do
          GenObject.new(__MODULE__, unquote(args))
        end
      end
    end
  end

  defmacro definterface(name, do: block) do
    quote do
      defmodule unquote(name) do
        import Kernel,
          except: [
            def: 1,
            defp: 1,
            defp: 2,
            defdelegate: 2,
            defguard: 1,
            defguardp: 1,
            defmacro: 1,
            defmacro: 2,
            defmacrop: 1,
            defmacrop: 2
          ]

        import GenObject, only: [def: 1]

        _ = unquote(block)
      end
    end
  end

  defmacro def({name, _, args}) when is_atom(name) and is_list(args) do
    arity = length(args)
    type_args = :lists.map(fn _ -> quote(do: term) end, :lists.seq(1, arity))

    quote do
      @callback unquote(name)(unquote_splicing(type_args)) :: term
      Kernel.def unquote(name)(unquote_splicing(args)) do
        GenObject.Object.dispatch(unquote(hd(args)), unquote(name), unquote(tl(args)))
      end
    end
  end

  defmodule Object do
    defstruct [:module, :state]

    defmacro deconstruct(pattern) do
      quote do
        %unquote(__MODULE__){module: __MODULE__, state: unquote(pattern)}
      end
    end

    @behaviour Access

    @impl true
    def fetch(object, item) do
      dispatch(object, :fetch, [item])
    end

    def build(module, state), do: %__MODULE__{module: module, state: state}
    def module(object), do: object.module
    def state(object), do: object.state
    def put_state(object, new_state), do: object |> module() |> build(new_state)

    def dispatch(object, message, args) do
      apply(module(object), message, [object | args])
    end
  end

  def new(module, opts \\ []) do
    Object.build(module, apply(module, :initialize, opts))
  end
end
