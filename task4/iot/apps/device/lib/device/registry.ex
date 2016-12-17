defmodule Device.Registry do
  def start_link(options \\ []) do
    IO.puts("Starting registry...")
    Agent.start_link(fn -> %{} end, [options])
	end

	def add({reference, device}) do
    IO.puts("Received a device with reference:")
    IO.inspect(reference)
	  Agent.update(__MODULE__, fn state -> Map.put(state, reference, device) end)
	end
    
  def remove(reference) do
    IO.puts("Removing a device:")
    IO.inspect(reference)
	  Agent.update(__MODULE__, fn state -> Map.delete(state, reference) end)
  end
    
	def list do
    IO.puts("Listing devices.")
	  Agent.get(__MODULE__, fn state -> Map.values(state) end)
	end
end
