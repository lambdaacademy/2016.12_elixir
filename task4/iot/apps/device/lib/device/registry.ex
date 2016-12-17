defmodule Device.Registry do

  def start_link(options \\ []) do
    Agent.start_link(fn -> %{} end, [options])
  end

  def add({reference, device}) do
    Agent.update(__MODULE__, fn state -> Map.put(state, reference, device) end)
  end

  def remove(reference) do
    Agent.update(__MODULE__, fn state -> Map.delete(state, reference) end)
  end

  def list do
    Agent.get(__MODULE__, fn state -> Map.values(state) end)
  end

end
