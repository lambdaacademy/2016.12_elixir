defmodule Webui.DeviceView do
  use Webui.Web, :view

  def devices, do: Device.Registry.list()

  def device(d) do
    text = "#{d.domain} – #{d.type} service at #{d.name}:#{d.port}"
    case d.type do
      "_http._tcp" ->
        Phoenix.HTML.raw("<a href='http://#{d.name}:#{d.port}/'>#{text}</a>")
      _ ->
        text
    end
  end

end
