# Task 1: Distributed Elixir Demo

To whet our appetite about the opportunities Elixir and Erlang VM gives us,
we'll run a simple Distributed Elixir demo.

First, to make sure the necessary system services are in place,
find out a hostname of one of your neighbour's machines - let's assume it's `x4`.
Run the following, substitute the hostname you found, but don't omit the `.local` suffix:

```sh
ping x4.local
```

Ping replies should return just fine, even though we don't rely on any
DNS server being present in the network.
This is due to mDNS, a zero configuration networking protocol,
implemented by Apple Bonjour on macOS and Avahi on Linux.

Let's proceed by compiling and running the following module:

```elixir
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
```

Can you tell what it does?
Type (or paste) the code into a file called `echo.ex` and compile it with:

```sh
elixirc echo.ex
```

We have our first server ready.
Let's run it, but make sure to pass the extra parameters when starting
the interactive shell and use your own hostname for the `--name` flag:

```sh
iex --name node1@x4.local --cookie qkee
```

`node1@x4.local` will be our address for Distributed Elixir communication.
Cookie is a parameter which limits communication to a certain subgroup
of Elixir nodes - only nodes with the same cookie can communicate with one another.
Once inside the shell, we can run the server with:

```
iex(node1@x4.local)1> Echo.start
#PID<0.71.0>
iex(node1@x4.local)2>
```

`#PID<0.71.0>` is the pid (process identifier) of our server.
Every process inside the VM has its own unique pid.
Moreover, pids also uniquely identify processes in a cluster
of interconnected nodes - we'll see that in a second.

If you're doing this task alone,
then start a second Elixir node in a different shell:

```sh
iex --name node2@x4.local --cookie qkee
```

If you're working in a group, you can skip the previous step,
and carry on with the next command from the first node (`node1@...`) you started,
but instead of using `node1@x4.local` below substitute your neighbours node name:

```
iex(node2@x4.local)1> send {Echo, :"node1@x4.local"}, "Hello from #{inspect self} at #{node}"
```

Your neighbour (or your first node, if you're running this just by yourself)
should've printed something similar to:

```
Echo: Hello from #PID<0.65.0> at node2@x4.local
```

Success!
To recap, here's what we did above:

- we used mDNS to resolve hostnames to their IP addresses in a local network,
  without any reliance on a central DNS server,
  i.e. in a completely distributed fashion

- we wrote our first Elixir server process, `spawn`ed it,
  and `register`ed it under a particular name

- we established Distributed Elixir communication between two Elixir nodes
  (also known as Erlang virtual machines) and exchanged messages between them


## Exercises

1.  Retry setting up the communication between nodes,
    but use a different cookie for each of them.
    Does the communication still work?

2.  Once you've sent some messages to your neighbours' nodes
    run `Node.list` - what do you get?

3.  Instead of running `Echo.start` you can manually register your shell's
    pid under a name, so that it's easily addressable from a connected node.
    Try doing so with:

    ```
    iex(node1@x4.local)1> Process.register(self, :sh)
    ```

    and then, from a different node, sending a message to it:

    ```
    iex(node3@x4.local)1> send {:sh, :"node1@x4.local"}, "message to :sh"
    ```

    Nothing gets printed on `node1` right away,
    but you'll see the message if you run:

    ```
    iex(node1@x4.local)2> flush
    "message to :sh"
    ```


## Further reading

-   [Elixir Getting Started: Processes](http://elixir-lang.org/getting-started/processes.html)

-   [Erlang Reference Manual: Processes](http://erlang.org/doc/reference_manual/processes.html)

    Most (if not all) Erlang documentation holds in the world of Elixir.
    However, reading it requires some more effort, as the examples are in Erlang.
    The Rosetta Stone for deciphering Erlang documentation
    is [Erlang/Elixir Syntax: A Crash Course](http://elixir-lang.org/crash-course.html).
    For the part about processes, however, the really useful piece of
    information is that all the Erlang BIFs for `spawn`ing, `register`ing, `link`ing,
    etc. are in the `Process` Elixir module.
