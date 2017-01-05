# Task 5: Raspberry(Pi) Dynamic Discovery


## Introduction


### mDNS and DNS Service Discovery

In computer networking, the multicast Domain Name System (mDNS) resolves host names
to IP addresses within small networks that do not include a local name server. [...]
mDNS can work in conjunction with DNS Service Discovery (DNS-SD).
From [Wikipedia: Multicast DNS](https://en.wikipedia.org/wiki/Multicast_DNS).

DNS-SD allows clients to discover a named list of service instances, given
a service type, and to resolve those services to hostnames using standard
DNS queries. [...]
Each service instance is described using a DNS SRV and DNS TXT (RFC 1035) record.
A client discovers the list of available instances for a given service type
by querying the DNS PTR (RFC 1035) record of that service type's name;
the server returns zero or more names of the form "<Service>.<Domain>",
each corresponding to a SRV/TXT record pair.
The SRV record resolves to the domain name providing the instance,
while the TXT can contain service-specific configuration parameter.
A client can then resolve the A/AAAA record for the domain name
and connect to the service.
From [Wikipedia: Zero-configuration networking - Service\_discovery](https://en.wikipedia.org/wiki/Zero-configuration_networking#Service_discovery).


### Nerves

Nerves defines an entirely new way to build embedded systems using Elixir.
It is specifically designed for embedded systems, not desktop or server systems.
You can think of Nerves as containing three parts:

-   Platform - a customized, minimal Buildroot-derived Linux that boots
    directly to the BEAM VM.

-   Framework - ready-to-go library of Elixir modules to get you up and
    running quickly.

-   Tooling - powerful command-line tools to manage builds, update firmware,
    configure devices, and more.

Taken together, the Nerves platform, framework, and tooling provide a highly
specialized environment for using Elixir to build advanced embedded devices.

From [Nerves: Getting Started][nerves:start].

[nerves:start]: https://hexdocs.pm/nerves/getting-started.html
[nerves:install]: https://hexdocs.pm/nerves/installation.html


## Experimentation


### Baking a Pi

Skim over Nerves [Installation][nerves:install] and [Getting Started][nerves:start].
This will give you a better understanding of the steps necessary to build
the `hello_networking` example from [erszcz/nerves\_examples][erszcz:examples].
Please note this repo is a fork of the official Nerves examples - the
networking demo is customised to our needs.

[erszcz:examples]: https://github.com/erszcz/nerves-examples

Follow these steps to get a firmware image for Raspberry Pi:

```
git clone https://github.com/erszcz/nerves-examples
cd nerves-examples/hello_network
mix local.hex
mix local.rebar
mix archive.install https://github.com/nerves-project/archives/raw/master/nerves_bootstrap.ez
mix deps.get
```

Before we proceed let's make sure we don't run into naming conflicts
if multiple Raspberries are present in the network.
Due to Nerves limitations this can't be done automatically - yet? Hopefully.
This diff shows the two places where we need to place our device's desired
hostname - make sure each one of you in the group has a unique value there:

```
$ git diff
diff --git a/hello_network/config/config.exs b/hello_network/config/config.exs
index 9d9c295..98d11f2 100644
--- a/hello_network/config/config.exs
+++ b/hello_network/config/config.exs
@@ -17,7 +17,7 @@ use Mix.Config
 #     Application.get_env(:hello_network, :key)
 #

-config :hello_network, hostname: "rpi7"
+config :hello_network, hostname: "rpi9"

 #
 # Or configure a 3rd-party app:
diff --git a/hello_network/rel/vm.args b/hello_network/rel/vm.args
index 956e31a..62eed72 100644
--- a/hello_network/rel/vm.args
+++ b/hello_network/rel/vm.args
@@ -1,6 +1,6 @@
 ## Start the Elixir shell
 -noshell
--name nerves@rpi7.local
+-name nerves@rpi9.local
 -setcookie rpi
 -user Elixir.IEx.CLI
 -extra --no-halt
```

With the hostname set, we're ready to generate the firmware image:

```
mix firmware
```

At this point the image file should be ready for _burning_ to an SD card:

```
$ ls -l _images/rpi/hello_network.fw
-rw-r--r--  1 erszcz  staff    19M Jan  5 11:49 _images/rpi/hello_network.fw
```

Let's proceed - place the SD card into your card reader.
`mix` might ask you about which device to write to if you have more than
one looking suitable - make sure not to overwrite your hard drive ;)

```
mix firmware.burn
```

If everything went fine, place the card in your Pi.
Attach a spare screen if you have one at hand - it might help
with troubleshooting if anything goes wrong.
Connect the Pi to the network switch, plug in the power cable
and `ping` from you laptop:

```
ping rpi9.local
```

Once the Raspberry boots up, you should start receiving replies:

```
$ ping rpi9.local
PING rpi9.local (192.168.2.3): 56 data bytes
64 bytes from 192.168.2.3: icmp_seq=0 ttl=64 time=0.952 ms
64 bytes from 192.168.2.3: icmp_seq=1 ttl=64 time=0.562 ms
^C
--- rpi9.local ping statistics ---
2 packets transmitted, 2 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 0.562/0.757/0.952/0.195 ms
```

Voilà!


### Distributed Elixir with the Pi

Since `ping` works, there's a good chance that Distributed Elixir will work too.
Let's try (`$` stands for system shell, `>` for IEx):

```
$ iex --name tracer@x4.local --cookie rpi
> Node.connect :"nerves@rpi9.local"
> Node.list
> :dbg.tracer()
> # we enable remote tracing of function calls on a different node
> :dbg.n(:"nerves@rpi9.local")
> :dbg.tpl(Mdns.Server, :send_service_response, [])
> :dbg.p(:all, :call)
```

Now, let's ping our Pi in a different shell:

```
ping rpi9.local
```

and watch IEx at the same time:

```
iex(tracer@x4.local)73> (<9978.107.0>) call 'Elixir.Mdns.Server':send_service_response([#{'__struct__' => 'Elixir.DNS.Resource',
   bm => [],
   class => in,
   cnt => 0,
   data => {192,168,2,3},
   domain => "rpi9.local",
   func => false,
   tm => undefined,
   ttl => 10,
   type => a}],#{'__struct__' => 'Elixir.DNS.Record',
  anlist => [],
  arlist => [],
  header => #{'__struct__' => 'Elixir.DNS.Header',
    aa => false,
    id => 0,
    opcode => query,
    pr => false,
    qr => false,
    ra => false,
    rcode => 0,
    rd => false,
    tc => false},
  nslist => [],
  qdlist => [#{'__struct__' => 'Elixir.DNS.Query',class => 32769,domain => "rpi9.local",type => a}]},#{'__struct__' => 'Elixir.Mdns.Server.State',
  ip => {192,168,2,3},
  services => [#{'__struct__' => 'Elixir.Mdns.Server.Service',
     data => [<<"txtvers=1">>,<<"port=4000">>],
     domain => <<"rpi9._http._tcp.local">>,
     ttl => 10,
     type => txt},
   #{'__struct__' => 'Elixir.Mdns.Server.Service',
     data => <<"rpi9._http._tcp.local">>,
     domain => <<"_http._tcp.local">>,
     ttl => 10,
     type => ptr},
   #{'__struct__' => 'Elixir.Mdns.Server.Service',
     data => <<"_http._tcp.local">>,
     domain => <<"_services._dns-sd._udp.local">>,
     ttl => 10,
     type => ptr},
   #{'__struct__' => 'Elixir.Mdns.Server.Service',
     data => ip,
     domain => <<"rpi9.local">>,
     ttl => 10,
     type => a}],
  udp => #Port<9978.827>})
```

Wow! We got a slight mess on the screen, but at least we can dynamically
inspect from our laptop what the app on Pi actually does - in realtime.

As the name suggests, `dbg` is the standard Erlang VM debugger.
It's not a stepwise debugger like `gdb` or debuggers built into IDEs.
It's a _tracing debugger_, convenient for getting execution traces of
highly concurrent systems, where stopping the program is not an option
due to a cascade of timeouts what would occur.


### Networking

TODO: go one by one: dns-sd subcommand -> relevant DNS record in hello_networking.ex


## Objectives

Based on the descriptions in _Introduction_ and the experiments carried out above,
let's set some objectives:

-   We want the `device` app from task #4 to discover when devices join
    and leave the network.
    A device might advertise different service types, not necessarily a web server,
    so the `Device` structure might need extension to accomodate that.
    A domain name (that's a hostname and the `.local` suffix),
    a service type and port seem to be a sensible set of data to store.
    For `_http._tcp` service type hyperlinking the entries would make sense,
    so that we can get to the device's interface with a single click
    (and we get a use case for storing the domain and port).

-   The device itself should register its presence using mDNS / DNS-SD.
    It should also set up a web interface and advertise the service,
    so that `device` can pick up the registration
    and make it show up in the device list of `webui`.
    The interface should at least display the device hostname.
    It can also offer the option to hide the device service from the
    network (unregister the TXT record - new browsers won't be able to connect);
    don't unregister the A record though,
    because the already connected browsers will lose access too!

-   One of the main Phoenix features are [Channels][phx:channels],
    which allow for soft-realtime behaviour of our webapps.
    Using a channel we can make the list of detected devices in `webui`
    refresh dynamically and without user intervention when devices
    join/leave the network.

[phx:channels]: http://www.phoenixframework.org/docs/channels


## Further reading

-   http://erlang.org/doc/man/dbg.html
-   http://stackoverflow.com/questions/1954894/using-trace-and-dbg-in-erlang
-   https://github.com/fishcakez/dbg might give a more Elixir-like output;
    builtin `dbg` prints Erlang terms, not Elixir terms
