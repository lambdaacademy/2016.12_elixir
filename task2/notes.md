# Task 2: MyAgent

One of the examples in Task 1 was a basic Elixir server,
which consisted of three functions: `start/0`, `init/0`, and `loop/1`.
Building on top of it we could build a more complex example like
the one (in Erlang) shown
in [The Basic Server](http://learnyousomeerlang.com/what-is-otp#the-basic-server)
section of [Learn you some Erlang](http://learnyousomeerlang.com).
The important takeaway from that example is redundancy we see in each
client side call: setting up a monitor (more on that later),
sending the request, waiting for the response or the monitor `DOWN` message...
as well as in the server receive loop: pattern matching on the message,
running the particular handler (e.g. `make_cat`), sending the response.
These parts are common in every client-server pair of processes
and the redundancy was spotted and fixed by introducing
`GenServer` - a _generic_ server.

Please skim through its documentation now (don't hesitate to get back to it later):

```
iex> h GenServer
```

`GenServer`s are one of the core building blocks of OTP based systems,
so knowing how to use them is pretty useful in practice.
While convenient, writing them also gets repetitive after a while,
so the Elixir standard library includes two more specific modules which
hide the details of using a `GenServer` behind
a more specialized interface - these are `Task` and `Agent`.
`Task` is about background processing,
while `Agent` about encapsulating state and providing safe access to it
in a concurrent environment.

In `config` directory we have a tiny Elixir library that uses an `Agent`.
In this task we'll implement `MyAgent`,
the subset of `Agent` interface required by `Config`.
We'll put `GenServer` to work to make it happen.
At the same time we'll get familiar with the basic structure
of an Elixir project.

First, let's run the tests to see whether `Config` actually works:

```sh
cd config/
mix deps.get
mix deps.compile
mix test
```

Mix is the standard Elixir build tool and we'll use it a lot,
but the above commands are enough for now.

As can be seen from `ConfigTest` test suite,
`Config` is a lib which allows us to access a tree-like configuration
structure defined by a [TOML file](https://github.com/toml-lang/toml):

```elixir
defmodule ConfigTest do
  use ExUnit.Case
  doctest Config

  setup do
    Config.start("test/examples/sample.toml")
    on_exit fn -> Config.stop end
  end

  test "get config option" do
    assert Config.get(:title) == "TOML Example"
    assert Config.get([:database, :server]) == "192.168.1.1"
    assert Config.get([:servers, :alpha, :ip]) == "10.0.0.1"
  end

  test "set config option" do
    # given
    assert Config.get(:title) == "TOML Example"
    assert Config.get([:servers, :alpha, :ip]) == "10.0.0.1"
    # when
    Config.set(:title, "New title")
    Config.set([:servers, :alpha, :ip], "10.0.0.10")
    # then
    assert Config.get(:title) == "New title"
    assert Config.get([:servers, :alpha, :ip]) == "10.0.0.10"
  end

end
```

Where `test/examples/sample.toml` looks as follows:

```toml
# This is a TOML document. Boom.

title = "TOML Example"

[owner]
name = "Tom Preston-Werner"
organization = "GitHub"
bio = "GitHub Cofounder & CEO\nLikes tater tots and beer."

[database]
server = "192.168.1.1"
ports = [ "8001", "8001", "8002" ]
connection_max = 5000

[servers]

# You can indent as you please. Tabs or spaces. TOML don't care.
    [servers.alpha]
  ip = "10.0.0.1"
    dc = "eqdc10"

[servers.beta]
ip = "10.0.0.2"
dc = "eqdc10"
```

We can also update the options at runtime,
but these changes aren't reflected in the file on disk - it stays
untouched no matter what we change in the in-memory configuration.

Now, make sure your git working copy is at tag `task2`
of this repository - otherwise, there'll be no surprise:

```sh
git checkout task2
```

Let's change the `Agent` implementation `Config` uses to `MyAgent`.
Open `config/config.exs` with your favourite editor and change:

```elixir
config :config, agent_impl: Agent
```

to

```elixir
config :config, agent_impl: MyAgent
```

Now rerun the tests again:

```sh
$ mix test
Compiling 1 file (.ex)
warning: function MyAgent.stop/1 is undefined or private
  lib/config.ex:15

warning: function MyAgent.get/2 is undefined or private
  lib/config.ex:17

warning: function MyAgent.update/2 is undefined or private
  lib/config.ex:19

Generated config app


  1) test get config option (ConfigTest)
     test/config_test.exs:10
     ** (RuntimeError) not implemented yet
     stacktrace:
       lib/my_agent.ex:4: MyAgent.start/2
       (config) lib/config.ex:9: Config.start/1
       test/config_test.exs:6: ConfigTest.__ex_unit_setup_0/1
       test/config_test.exs:1: ConfigTest.__ex_unit__/2



  2) test set config option (ConfigTest)
     test/config_test.exs:16
     ** (RuntimeError) not implemented yet
     stacktrace:
       lib/my_agent.ex:4: MyAgent.start/2
       (config) lib/config.ex:9: Config.start/1
       test/config_test.exs:6: ConfigTest.__ex_unit_setup_0/1
       test/config_test.exs:1: ConfigTest.__ex_unit__/2



Finished in 0.05 seconds
2 tests, 2 failures

Randomized with seed 661849
```

Look at how `Config` uses the `Agent` interface, study `Agent`
and `GenServer` docs and come up with an implementation
of `MyAgent` that will make the tests pass.
Approach it step by step - make _get config option_ work first
and then go to _set config option_.
The solution will be about 20 lines of code,
depending on your preferred formatting.
