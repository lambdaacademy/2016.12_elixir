defmodule Device.Scanner do
  use GenServer
  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, :ok, [options])
  end
    

  def init(:ok) do
    IO.puts("Setting up scanner...")
    :dnssd.start
    :dnssd.browse("_http._tcp")
    {:ok, []}
  end

  def handle_info(msg, state) do
	  {:dnssd, reference, {_, change,{name, type , domain}}} = msg

    case change do
      :add ->
        {:ok, {_, port, _}} = :dnssd.resolve_sync name, type , domain
        
        device = %Device{
                  name: name,
                  domain: domain,
                  data: "port=#{port}"
                }
        Device.Registry.add({reference, device})
  
      :remove -> Device.Registry.remove(reference)
    end

    {:noreply, state}
  end
end
