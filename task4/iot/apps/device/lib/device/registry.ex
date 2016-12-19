defmodule Device.Registry do

  def start_link(options \\ []) do
    Agent.start_link(fn -> %{} end, [options])
  end

  def add({device_id, device}) do
    Agent.update(__MODULE__, fn state -> Map.put(state, device_id, device) end)
  end

  def remove(device_id) do
    Agent.update(__MODULE__, fn state -> Map.delete(state, device_id) end)
  end

  def list do
    Agent.get(__MODULE__, fn state -> Map.values(state) end)
  end

end
