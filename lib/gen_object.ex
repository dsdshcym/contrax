defmodule GenObject do
  defmacro __using__(opts) do
    interfaces = Keyword.get(opts, :implements, [])

    quote bind_quoted: [interfaces: interfaces] do
      implement = __MODULE__

      {protocols, behaviours} =
        Enum.split_with(
          interfaces,
          fn module ->
            try do
              Protocol.assert_protocol!(module) == :ok
            rescue
              _e in ArgumentError -> false
            end
          end
        )

      for behaviour <- behaviours do
        @behaviour behaviour
      end

      for protocol <- protocols do
        @behaviour protocol
      end

      defp construct(state) do
        __MODULE__.Object.build(__MODULE__, state)
      end

      defmacrop deconstruct(pattern) do
        quote do
          %{module: __MODULE__, state: unquote(pattern)}
        end
      end

      @before_compile GenObject

      defmodule Object do
        defstruct [:module, :state]

        for behaviour <- behaviours do
          @behaviour behaviour

          for {function, arity} <- behaviour.behaviour_info(:callbacks) do
            args = Macro.generate_unique_arguments(arity, __MODULE__)

            @impl behaviour
            defdelegate unquote(function)(unquote_splicing(args)), to: implement
          end
        end

        for protocol <- protocols do
          defimpl protocol do
            for {function, arity} <- protocol.__protocol__(:functions) do
              args = Macro.generate_unique_arguments(arity, __MODULE__)

              defdelegate unquote(function)(unquote_splicing(args)), to: implement
            end
          end
        end

        def build(module, state), do: %__MODULE__{module: module, state: state}
        def module(object), do: object.module
        def state(object), do: object.state
        def put_state(object, new_state), do: object |> module() |> build(new_state)

        def dispatch(object, message, args) do
          apply(module(object), message, [object | args])
        end
      end
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
          __MODULE__.Object.build(__MODULE__, initialize(unquote_splicing(args)))
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
        GenObject.dispatch(unquote(hd(args)), unquote(name), unquote(tl(args)))
      end
    end
  end

  def dispatch(object, message, args) do
    object.__struct__.dispatch(object, message, args)
  end
end
