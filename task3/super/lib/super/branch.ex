defmodule Super.Branch.Supervisor do
  use Supervisor

  def start_link do
    ## TODO: Depending on whether :name is defined the supervisor
    ## will have a human-readable name in Observer or will be identified
    ## just by the pid.
    #Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(Super.Branch.Worker, [], id: {Super.Branch.Worker, 1}),
      worker(Super.Branch.Worker, [], id: {Super.Branch.Worker, 2}),
      worker(Super.Branch.Worker, [], id: {Super.Branch.Worker, 3}),
      worker(Super.Branch.Worker, [], id: {Super.Branch.Worker, 4}),
      worker(Super.Branch.Worker, [], id: {Super.Branch.Worker, 5})
    ]
    ## TODO: Try changing the strategy and doing Process.exit/2
    ## on one of the children. What changes in the process hierarchy?
    supervise(children, strategy: :one_for_one)
    #supervise(children, strategy: :one_for_all)
  end

end

defmodule Super.Branch.Worker do
  use GenServer

  def start_link(default \\ []), do: GenServer.start_link(__MODULE__, [], default)

  def terminate(reason, _state) do
    IO.puts("worker #{inspect self} terminating: #{inspect reason}")
    :ok
  end

end
