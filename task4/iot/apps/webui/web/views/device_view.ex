defmodule Webui.DeviceView do
  use Webui.Web, :view

  def devices, do: Device.Registry.list()

end
