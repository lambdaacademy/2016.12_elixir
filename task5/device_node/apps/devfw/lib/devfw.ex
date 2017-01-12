defmodule DevFW do
  use Application

  defmodule Net do

    require Logger

    alias Nerves.Networking

    @hostname Application.get_env(:devfw, :hostname)

    def setup(iface) do
      # Don't start networking unless we're on nerves
      unless :os.type == {:unix, :darwin} do
        {:ok, _} = Networking.setup iface, hostname: @hostname
        Logger.debug("network settings: #{inspect Networking.settings(iface)}")
        publish_node_via_mdns(iface)
      end
      {:ok, self}
    end

    def publish_node_via_mdns(interface) do
      Logger.debug("publishing via MDNS")
      iface = Networking.settings(interface)
      hostname = iface.hostname
      ip = ip_to_tuple(iface.ip)
      Mdns.Server.start
      # Make `ping rpi1.local` from a laptop work.
      Mdns.Server.set_ip(ip)
      Mdns.Server.add_service(%Mdns.Server.Service{
        domain: "#{hostname}.local",
        data: :ip,
        ttl: 10,
        type: :a
      })
      # Make `dns-sd -B _services._dns-sd._udp` show
      # an HTTP service.
      Mdns.Server.add_service(%Mdns.Server.Service{
        domain: "_services._dns-sd._udp.local",
        data: "_http._tcp.local",
        ttl: 10,
        type: :ptr
      })
      Mdns.Server.add_service(%Mdns.Server.Service{
        domain: "_http._tcp.local",
        data: "#{hostname}._http._tcp.local",
        ttl: 10,
        type: :ptr
      })
      # This should be the DNS-SD way of defining a service instance:
      # its priority, weight and host.
      # It doesn't work.
      # The packet sent by Mdns is corrupt as seen by Wireshark
      # and undecodable by Erlang :inet_dns.decode/1.
      #Mdns.Server.add_service(%Mdns.Server.Service{
        #  domain: "#{hostname}._http._tcp.local",
        #  data: "0 0 4000 #{hostname}.local",
        #  ttl: 10,
        #  type: :srv
        #})
      Mdns.Server.add_service(%Mdns.Server.Service{
        domain: "#{hostname}._http._tcp.local",
        data: ["txtvers=1", "port=4000"],
        ttl: 10,
        type: :txt
      })
      Logger.debug "publish via MDNS done"
      :ok
    end

    defp ip_to_tuple(ip) do
      ( for b <- String.split(ip, "."), do: String.to_integer(b) )
      |> :erlang.list_to_tuple()
    end

  end

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      worker(Task, [fn -> DevFW.Net.setup(:eth0) end], restart: :transient),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DevFW.Supervisor]
    Supervisor.start_link(children, opts)
  end

end