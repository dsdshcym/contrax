defmodule GenObject do
  def new(module, opts \\ []) do
    build(module, apply(module, :initialize, opts))
  end

  def fire(object, message) do
    module(object).handle_fire(state(object), message)
  end

  def morph(object, message) do
    new_state = module(object).handle_morph(state(object), message)

    put_state(object, new_state)
  end

  def ask(object, message) do
    {new_state, output} = module(object).handle_ask(state(object), message)

    {put_state(object, new_state), output}
  end

  defp build(module, state), do: {module, state}
  defp module({module, _state}), do: module
  defp state({_module, state}), do: state
  defp put_state(object, new_state), do: object |> module() |> build(new_state)
end
