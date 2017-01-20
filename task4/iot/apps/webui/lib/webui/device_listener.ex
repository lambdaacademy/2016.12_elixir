defmodule Webui.DeviceListener do
  use GenServer

  def start_link(options \\ []), do: GenServer.start_link(__MODULE__, [], options)

  def init([]) do
    Device.Registry.subscribe(self())
    {:ok, :state}
  end

  def handle_info({:add_device, device_id, device}, state) do
    Webui.Endpoint.broadcast!("device:__index__", "add_device",
                              %{"id" => device_id, "device" => device})
    {:noreply, state}
  end
  def handle_info({:remove_device, device_id}, state) do
    Webui.Endpoint.broadcast!("device:__index__", "remove_device", %{"id" => device_id})
    {:noreply, state}
  end
  def handle_info(info, state) do
    super(info, state)
  end

end
