defmodule Device.Scanner do
  require Logger
  use GenServer

  @services      "_services._dns-sd._udp.local"
  @service_types ["_epmd._tcp.local.", "_http._tcp.local.",
                  "_epmd._tcp.local", "_http._tcp.local"]

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, :ok, [options])
  end

  def init(:ok) do
    {:ok, ref} = :dnssd.query_record(@services, "PTR")
    {:ok, %{{@services, "PTR"} => ref}}
  end

  def handle_info({:dnssd, ref, {:query_record, change, {domain, rtype, _, rdata} = params}} = m, state) do
    try do
      next = case {domain, domain in @service_types, rtype} do
        {@services <> dot, _, _} when dot == "." or dot == "" ->
          { [{:stop_query, {domain, rtype}}],
            [{:subquery, get_domain(params), "PTR"}] }
        {_, true, _} ->
          { [{:stop_query, {domain, rtype}}],
            [{:subquery, get_domain(params), "TXT"}] }
        {_, false, "TXT"} ->
          { [{:remove_device, domain}],
            [{:add_device, domain, parse_txt_data(rdata)}] }
        {_, _, _} ->
          { [], [] }
      end
      new_state = go(add_or_remove?(change, next), state)
      Logger.debug("new state: #{inspect(new_state)}")
      {:noreply, new_state}
    catch _, r ->
      Logger.error("error #{inspect(r)} on #{inspect(m)}")
      {:noreply, state}
    end
  end

  def handle_info(msg, state) do
    Logger.info("unhandled: #{inspect(msg)}")
    super(msg, state)
  end

  def add_or_remove?(:add,    {remove_ops, next_ops}), do: remove_ops ++ next_ops
  def add_or_remove?(:remove, {remove_ops, _}),        do: remove_ops

  def go(next, state) when is_list(next), do: List.foldl(next, state, &go/2)
  def go(nil, state),                     do: state
  def go({:stop_query, old_query} = op, state) do
    Logger.info("stop query: #{inspect(old_query)}")
    Map.delete(state, old_query)
  end
  def go({:subquery, domain, rtype} = op, state) do
    Logger.info("subquery: #{domain} #{rtype}")
    {:ok, ref} = :dnssd.query_record(domain, rtype)
    Map.put(state, {domain, rtype}, ref)
  end
  def go({:remove_device, domain}, state) do
    Logger.info("remove device: #{domain}")
    Device.Registry.remove(domain)
    state
  end
  def go({:add_device, domain, service}, state) do
    Logger.info("add device: #{domain} #{inspect(service)}")
    device = %Device{
      name: name_from_domain(domain),
      domain: domain,
      port: service["port"],
      type: type_from_domain(domain)
    }
    Device.Registry.add({domain, device})
    state
  end

  def get_domain({_, _, _, rdata}) do
    rdata
    |> (&Regex.replace(~r/[^-a-zA-Z0-9_@:]+/, &1, " ")).()
    |> String.trim()
    |> String.replace(" ", ".")
  end

  def get_service_instance({_, _, _, rdata}) do
    {name, rest} = rdata
                    |> String.to_charlist()
                    |> Enum.drop(1)
                    |> Enum.split_while(fn 5 -> false; _ -> true end)
    domain = rest
              |> Enum.drop(1)
              |> Enum.drop_while(fn 5 -> false; _ -> true end)
              |> List.to_string()
              |> String.trim_trailing(<<0>>)
    "#{name}.#{domain}."
  end

  def name_from_domain(domain) do
    domain
    |> String.split(".", trim: true)
    |> Enum.filter(fn "_" <> _ -> false; _ -> true end)
    |> Enum.join(".")
  end

  def type_from_domain(domain) do
    domain
    |> String.split(".")
    |> Enum.filter(fn "_" <> _ -> true; _ -> false end)
    |> Enum.join(".")
  end

  defp parse_txt_data(rdata) do
    for keyval <- String.split(rdata, "\t", trim: true), into: %{}, do:
    List.to_tuple( String.split(keyval, "=") )
  end

end
