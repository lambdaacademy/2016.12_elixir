defmodule Webui.DeviceChannel do
  use Phoenix.Channel

  def join("device:__index__", _message, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end
  def join("device:" <> _device_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_info(:after_join, socket) do
    for d <- Device.Registry.list() do
      push(socket, "add_device", %{"id" => d.domain, "device" => d})
    end
    {:noreply, socket}
  end

end
