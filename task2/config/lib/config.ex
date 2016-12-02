defmodule Config do

  @agent Agent
  @name __MODULE__

  def start(file) do
    @agent.start(fn ->
      File.read!(file) |> Tomlex.load
    end, name: @name)
    :ok
  end

  def stop, do: @agent.stop @name

  def get(path), do: @agent.get(@name, &(get_(&1, path)))

  def set(path, value), do: @agent.update(@name, &(set_(&1, path, value)))

  defp get_(config, [key]), do: get_(config, key)
  defp get_(config, [key | path]), do: get_(config[key], path)
  defp get_(config, key) when not is_list(key), do: config[key]

  defp set_(config, path, value), do: decompose([], config, path, value)

  defp decompose(stack, config, [key], value), do:
    decompose(stack, config, key, value)
  defp decompose(stack, config, [key | path], value), do:
    decompose([{key, config} | stack], config[key], path, value)
  defp decompose(stack, config, key, value) when not is_list(key), do:
    rebuild(stack, %{ config | key => value })

  defp rebuild([], config), do: config
  defp rebuild([{key, config} | rest], inner_config), do:
    rebuild(rest, %{ config | key => inner_config })

end
