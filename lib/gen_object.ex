defmodule GenObject do
  defmacro __using__(_opts) do
    quote do
      @before_compile GenObject
    end
  end

  defmacro __before_compile__(env) do
    initializes =
      env.module
      |> Module.definitions_in(:def)
      |> Enum.filter(&match?({:initialize, _}, &1))

    for {:initialize, arity} <- initializes do
      args = Macro.generate_unique_arguments(arity, env.module)

      quote do
        def new(unquote_splicing(args)) do
          GenObject.new(__MODULE__, unquote_splicing(args))
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
            def: 2,
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

  defmacro def([{:morph, {name, _, args}}]) when is_atom(name) and is_list(args) do
    quote do
      Kernel.def unquote(name)(unquote_splicing(args)) do
        GenObject.morph(unquote(hd(args)), unquote(name), unquote(tl(args)))
      end
    end
  end

  defmacro def([{:ask, {name, _, args}}]) when is_atom(name) and is_list(args) do
    quote do
      Kernel.def unquote(name)(unquote_splicing(args)) do
        GenObject.ask(unquote(hd(args)), unquote(name), unquote(tl(args)))
      end
    end
  end

  def new(module, opts \\ []) do
    build(module, apply(module, :initialize, opts))
  end

  def fire(object, message) do
    module(object).handle_fire(state(object), message)
  end

  def morph(object, message, args) do
    new_state = apply(module(object), message, [state(object) | args])

    put_state(object, new_state)
  end

  def ask(object, message, args) do
    {new_state, output} = apply(module(object), message, [state(object) | args])

    {put_state(object, new_state), output}
  end

  defp build(module, state), do: {module, state}
  defp module({module, _state}), do: module
  defp state({_module, state}), do: state
  defp put_state(object, new_state), do: object |> module() |> build(new_state)
end
