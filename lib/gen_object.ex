defmodule GenObject do
  defmacro __using__(opts) do
    interfaces = Keyword.get(opts, :implements, [])

    quote bind_quoted: [interfaces: interfaces] do
      implement = __MODULE__

      {protocols, behaviours} =
        Enum.split_with(
          interfaces,
          fn module ->
            Code.ensure_loaded?(module) and function_exported?(module, :__protocol__, 1) and
              module.__protocol__(:module) == module
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
      defprotocol unquote(name) do
        import Protocol, except: [def: 1]
        import GenObject, only: [defcallback: 1]
        import GenObject.Case, only: [defterms: 2]
        import Kernel

        _ = unquote(block)
      end
    end
  end

  defmacro defcallback(signature) do
    quote do
      Protocol.def(unquote(signature))
    end
  end

  defmodule Case do
    defmacro __using__(opts) do
      for = Keyword.fetch!(opts, :for)
      case_opts = Keyword.delete(opts, :for)

      quote do
        use unquote(for).Case, unquote(case_opts)
      end
    end

    defmacro defterms(vars, do: block) do
      block = {:quote, [], [[do: block]]}
      default_subjects = Keyword.fetch!(vars, :subjects)

      quote do
        # TODO: raise if defterms is not called inside an interface module

        defmodule Case do
          use ExUnit.Callbacks

          import ExUnit.Assertions

          defmacro __using__(opts) do
            subjects = Keyword.get(opts, :subjects, [])

            defaults =
              for name <- unquote(default_subjects) do
                quote do
                  defp unquote(name)() do
                    raise "xxx"
                  end

                  defoverridable([{unquote(name), 0}])
                end
              end

            privates =
              for {name, body} <- subjects do
                quote do
                  defp unquote(name)() do
                    unquote(body)
                  end
                end
              end

            {:__block__, [], [unquote(block) | defaults ++ privates]}
          end
        end
      end
    end
  end
end
