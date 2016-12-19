defmodule Device.Scanner do
  use GenServer

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, :ok, [options])
  end

  def init(:ok) do
    :dnssd.start
    :dnssd.browse("_http._tcp")
    {:ok, []}
  end

  def handle_info(msg, state) do
    {:dnssd, _, {_, change,{name, type , domain}}} = msg
    device_id = {name, domain}

    case change do
      :add ->
        {:ok, {_, port, _}} = :dnssd.resolve_sync name, type , domain

        device = %Device{
                  name: name,
                  domain: domain,
                  data: "port=#{port}"
                }
        Device.Registry.add({device_id, device})

      :remove -> Device.Registry.remove(device_id)
    end
    {:noreply, state}
  end

end
