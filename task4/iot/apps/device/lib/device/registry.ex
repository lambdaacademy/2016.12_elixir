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
      new = update_in(state.devices, &Map.put(&1, device_id, device))
      for {pid} <- new.subscribers do
        send(pid, {:add_device, device_id, device})
      end
      new
    end)
  end

  def remove(device_id) do
    Agent.update(__MODULE__, fn state ->
      new = update_in(state.devices, &Map.delete(&1, device_id))
      for {pid} <- new.subscribers do
        send(pid, {:remove_device, device_id})
      end
      new
    end)
  end

  def list() do
    Agent.get(__MODULE__, fn state ->
      Map.values(state.devices)
    end)
  end

  def subscribe(pid) do
    Agent.update(__MODULE__, fn state ->
      for {device_id, device} <- Map.to_list(state.devices) do
        send(pid, {:add_device, device_id, device})
      end
      update_in(state.subscribers, &List.keystore(&1, pid, 1, {pid}))
    end)
  end

  def unsubscribe(pid) do
    Agent.update(__MODULE__, fn state ->
      update_in(state.subscribers, &List.keydelete(&1, pid, 1))
    end)
  end

end
