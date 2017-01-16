defmodule Device.Scanner do
  require Logger
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
    Logger.info("in: #{inspect msg}")
    {:dnssd, _, {_, change, {name, type, domain}}} = msg
    device_id = {name, domain}

    case change do
      :add ->
        case :dnssd.resolve_sync(name, type, domain) do
          {:ok, {_, port, _}} ->
            device = %Device{
              name: name,
              domain: domain,
              data: "port=#{port}"
            }
            Device.Registry.add({device_id, device})
          {:error, :timeout} ->
            Logger.info("resolve_sync timeout")
            :ok
        end
      :remove ->
        Device.Registry.remove(device_id)
    end
    {:noreply, state}
  end

end
