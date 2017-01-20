defmodule Device.Registry do

  defmodule State do
    defstruct [devices: %{},
               subscribers: []]
  end

  def start_link(options \\ []) do
    Agent.start_link(fn -> %State{} end, [options])
  end

  def add({device_id, device}) do
    Agent.update(__MODULE__, fn state ->
      update_in(state.devices, &Map.put(&1, device_id, device))
    end)
  end

  def remove(device_id) do
    Agent.update(__MODULE__, fn state ->
      update_in(state.devices, &Map.delete(&1, device_id))
    end)
  end

  def list do
    Agent.get(__MODULE__, fn state ->
      Map.values(state.devices)
    end)
  end

end
