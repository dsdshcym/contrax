defmodule GenObject do
  def new(module, opts \\ []) do
    build(module, apply(module, :initialize, opts))
  end

  def dispatch(object, message) do
    case module(object).handle_dispatch(state(object), message) do
      {:no_output, new_state} ->
        put_state(object, new_state)

      {:output, new_state, output} ->
        {put_state(object, new_state), output}
    end
  end

  defp build(module, state), do: {module, state}
  defp module({module, _state}), do: module
  defp state({_module, state}), do: state
  defp put_state(object, new_state), do: object |> module() |> build(new_state)
end
