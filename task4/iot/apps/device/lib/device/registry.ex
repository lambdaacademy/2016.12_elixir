defmodule Device.Registry do
  use GenServer

  @server __MODULE__

  defmodule State do
    defstruct [devices: %{},
               subscribers: Map.new()]
  end


  ## API

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, [], Keyword.merge(options, [name: @server]))
  end

  def add({device_id, device}), do:
    GenServer.call(@server, {:add_device, device_id, device})

  def remove(device_id), do:
    GenServer.call(@server, {:remove_device, device_id})

  def list(), do:
    GenServer.call(@server, :list)

  def subscribe(pid), do:
    GenServer.call(@server, {:subscribe, pid})

  def unsubscribe(pid), do:
    GenServer.call(@server, {:unsubscribe, pid})


  ## Implementation

  def init([]), do: {:ok, %State{}}

  def handle_call({:add_device, device_id, device}, _from, state) do
    new = update_in(state.devices, &Map.put(&1, device_id, device))
    for pid <- Map.values(new.subscribers) do
      send(pid, {:add_device, device_id, device})
    end
    {:reply, :ok, new}
  end

  def handle_call({:remove_device, device_id}, _from, state) do
    new = update_in(state.devices, &Map.delete(&1, device_id))
    for pid <- Map.values(new.subscribers) do
      send(pid, {:remove_device, device_id})
    end
    {:reply, :ok, new}
  end

  def handle_call(:list, _from, state) do
    {:reply, Map.values(state.devices), state}
  end

  def handle_call({:subscribe, pid}, _from, state) do
    mref = Process.monitor(pid)
    for {device_id, device} <- Map.to_list(state.devices) do
      send(pid, {:add_device, device_id, device})
    end
    {:reply, :ok, update_in(state.subscribers, &Map.put(&1, mref, pid))}
  end

  def handle_call({:unsubscribe, pid}, _from, state) do
    {reply, new} = case List.keyfind(state.subscribers, pid, 1) do
      {mref, ^pid} ->
        Process.demonitor(pid)
        {:ok, update_in(state.subscribers, &Map.delete(&1, mref))}
      nil ->
        {{:error, :not_subscribed}, state}
    end
    {:reply, reply, new}
  end

  def handle_call(msg, from, state) do
    super(msg, from, state)
  end

  def handle_info({DOWN, mref, :process, _pid, _info}, state) do
    {:noreply, update_in(state.subscribers, &Map.delete(&1, mref))}
  end
  def handle_info(info, state) do
    super(info, state)
  end

end
