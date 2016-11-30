# file: echo.ex
defmodule Echo do

  def start, do: Process.spawn(__MODULE__, :init, [], [])

  def init do
    Process.register(self, __MODULE__)
    loop
  end

  defp loop do
    receive do
      :stop -> :ok
      msg -> IO.puts("echo: #{msg}")
             loop
    end
  end

end
