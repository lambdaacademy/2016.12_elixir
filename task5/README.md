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
the server returns zero or more names of the form `<service>.<domain>`,
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
Due to Nerves limitations this can't be done automatically.
Yet? Hopefully.
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
due to a cascade of timeouts that would occur.


### Networking

We now know that `ping` and Distributed Elixir work with the Nerves
Raspberry Pi system.
What makes it work, though?

When we run `ping rpi9.local` the operating system has
to resolve the `rpi9.local` name to an IP address.
In very broad strokes, the OS can do it through the `/etc/hosts` file,
which contains static mappings, through a query to a DNS server
(which might result in subqueries from the DNS server to other DNS servers),
or in case of mDNS through a UDP broadcast in the local network.
No matter whether it's a request to a server or a UDP broadcast,
the [DNS request and record type][wiki:record-types] formats are the same.

[wiki:record-types]: https://en.wikipedia.org/wiki/List_of_DNS_record_types

Direct resolution of a domain name to an IP address is defined
by a DNS A (_address_) type record.
Apart from using `ping` we can run such an mDNS query directly with
`dns-sd`/macOS or `avahi-resolve`/Linux
(`-G`/get `v4`/IPv4 address for domain name `rpi9.local`):

```
$ dns-sd -G v4 rpi9.local
DATE: ---Mon 09 Jan 2017---
14:34:01.244  ...STARTING...
Timestamp     A/R Flags if Hostname                               Address                                      TTL
14:34:01.499  Add     3 11 rpi9.local.                            192.168.2.3                                  10
14:34:01.499  Add     2  8 rpi9.local.                            192.168.2.3                                  10
^C
```

Or more directly (`-Q`/query domain name `rpi9.local` for A records):

```
$ dns-sd -Q rpi9.local a
DATE: ---Mon 09 Jan 2017---
12:57:38.528  ...STARTING...
Timestamp     A/R Flags if Name                          Type  Class   Rdata
12:57:38.761  Add     3 11 rpi9.local.                   Addr   IN     192.168.2.3
12:57:38.761  Add     2  8 rpi9.local.                   Addr   IN     192.168.2.3
^C
```

Let's have a look
at [`hello_network.ex` A record registration](https://github.com/erszcz/nerves-examples/blob/f788e8b8a0bc73a8646b033d9ef1b3a6e64c890a/hello_network/lib/hello_network.ex#L33-L39):

```elixir
# Make `ping rpi1.local` from a laptop work.
Mdns.Server.set_ip(eth0ip4)
Mdns.Server.add_service(%Mdns.Server.Service{
  domain: "#{hostname}.local",
  data: :ip,
  ttl: 10,
  type: :a
})
```

We see that there's a direct correspondence between the query type we run
and the _service_/_record_ we register with mDNS.

That's all nice, but what if we want to discover services in a completely unknown environment,
without prior knowledge of the domain name to look up?
In other words, where to get `rpi9.local` from?
That's the problem DNS Service Discovery mentioned in the Introduction addresses.

From the client perspective, we first have to discover what types of
services are available in our network neighbourhood (`-B`/browse domain):

```
$ dns-sd -B _services._dns-sd._udp
Browsing for _services._dns-sd._udp
DATE: ---Mon 09 Jan 2017---
14:53:44.070  ...STARTING...
Timestamp     A/R    Flags  if Domain               Service Type         Instance Name
14:53:44.071  Add        2   4 .                    _tcp.local.          _homekit
14:53:44.257  Add        3  11 .                    _tcp.local.          _ssh
14:53:44.257  Add        3  11 .                    _tcp.local.          _sftp-ssh
14:53:44.257  Add        3   4 .                    _tcp.local.          _ssh
14:53:44.257  Add        3   4 .                    _tcp.local.          _sftp-ssh
14:53:44.257  Add        3   8 .                    _tcp.local.          _ssh
14:53:44.257  Add        2   8 .                    _tcp.local.          _sftp-ssh
14:53:44.359  Add        3   4 .                    _tcp.local.          _teamviewer
14:53:44.359  Add        3  11 .                    _tcp.local.          _http
14:53:44.359  Add        2   8 .                    _tcp.local.          _http
^C
```

Using a direct query we get the same information with (query for PTR records):

```
$ dns-sd -Q _services._dns-sd._udp.local ptr
DATE: ---Mon 09 Jan 2017---
15:28:42.588  ...STARTING...
Timestamp     A/R Flags if Name                          Type  Class   Rdata
15:28:42.589  Add     3  4 _services._dns-sd._udp.local. PTR    IN     _homekit._tcp.local.
15:28:42.589  Add     3 11 _services._dns-sd._udp.local. PTR    IN     _ssh._tcp.local.
15:28:42.589  Add     3 11 _services._dns-sd._udp.local. PTR    IN     _sftp-ssh._tcp.local.
15:28:42.590  Add     3  4 _services._dns-sd._udp.local. PTR    IN     _ssh._tcp.local.
15:28:42.590  Add     3  4 _services._dns-sd._udp.local. PTR    IN     _sftp-ssh._tcp.local.
15:28:42.590  Add     3  8 _services._dns-sd._udp.local. PTR    IN     _ssh._tcp.local.
15:28:42.590  Add     3  8 _services._dns-sd._udp.local. PTR    IN     _sftp-ssh._tcp.local.
15:28:42.590  Add     3  4 _services._dns-sd._udp.local. PTR    IN     _teamviewer._tcp.local.
15:28:42.590  Add     2  4 _services._dns-sd._udp.local. PTR    IN     _pblipc._tcp.local.
15:28:42.859  Add     3 11 _services._dns-sd._udp.local. PTR    IN     _http._tcp.local.
15:28:42.859  Add     2  8 _services._dns-sd._udp.local. PTR    IN     _http._tcp.local.
^C
```

`_services._dns-sd._udp` is the domain defined by [DNS-SD RFC](https://www.ietf.org/rfc/rfc6763.txt)
for service type discovery.
In other words, it's the go-to domain for the question: "what service types are present around me?"
[`hello_network` registers the following record under this domain](https://github.com/erszcz/nerves-examples/blob/f788e8b8a0bc73a8646b033d9ef1b3a6e64c890a/hello_network/lib/hello_network.ex#L41-L48):

```elixir
Mdns.Server.add_service(%Mdns.Server.Service{
  domain: "_services._dns-sd._udp.local",
  data: "_http._tcp.local",
  ttl: 10,
  type: :ptr
})
```

In general, having received the responses, we would go one by one thorough `_homekit`, `_ssh`,
`_sftp-ssh`, ... to discover the particular services.
This time we know there's `_http._tcp` present, but the question we want
to answer is "what kinds of HTTP services are present?"
One of them can be a webmail service,
another one can be a router configuration panel,
yet another one a printer interface.
Let's find out:

```
$ dns-sd -B _http._tcp local
Browsing for _http._tcp.local
DATE: ---Mon 09 Jan 2017---
15:21:29.047  ...STARTING...
Timestamp     A/R    Flags  if Domain               Service Type         Instance Name
15:21:29.196  Add        3  11 local.               _http._tcp.          rpi9
15:21:29.197  Add        2   8 local.               _http._tcp.          rpi9
# we plug in another Raspberry Pi
15:21:34.526  Add        3  11 local.               _http._tcp.          rpi7
15:21:34.526  Add        2   8 local.               _http._tcp.          rpi7
^C
```

Direct query:

```
$ dns-sd -Q _http._tcp.local ptr
DATE: ---Mon 09 Jan 2017---
15:27:29.633  ...STARTING...
Timestamp     A/R Flags if Name                          Type  Class   Rdata
15:27:29.871  Add     3 11 _http._tcp.local.             PTR    IN     rpi9._http._tcp.local.
15:27:29.871  Add     2  8 _http._tcp.local.             PTR    IN     rpi9._http._tcp.local.
15:27:30.001  Add     3 11 _http._tcp.local.             PTR    IN     rpi7._http._tcp.local.
15:27:30.001  Add     2  8 _http._tcp.local.             PTR    IN     rpi7._http._tcp.local.
^C
```

As seen above we treat each of our devices as a different service kind,
hence we get `rpi7` and `rpi9` in the responses.
`rpi9._http._tcp.local` can be read as "service `rpi9` of type `_http._tcp` in the `local` domain".

In order to connect to our discovered services we need to do one last
step - figure out service instances (for example, a webmail service can be
provided by multiple hosts / web servers at the same time - it doesn't
matter which one we connect to).

According to DNS-SD we would do that by looking up both SRV and TXT record types,
but experimenting with the Elixir mDNS library uncovered a bug in SRV record registration.
An SRV record would give us the hostname, while a TXT record would give us
the port of the service instance to connect to - all the information to access a service.
However, since in the previous step we decided that each Raspberry is its own "service kind",
we'll make the assumption that the only hostname registered for "service kind"
`rpi9._http._tcp.local` is `rpi9.local`.
We can't rely on "the standards compliant" way of service instance resolution,
but we still can perform a TXT record lookup and use the port stored within:

```
$ dns-sd -Q rpi9._http._tcp.local txt
DATE: ---Mon 09 Jan 2017---
16:02:17.779  ...STARTING...
Timestamp     A/R Flags if Name                          Type  Class   Rdata
16:02:18.053  Add     3 11 rpi9._http._tcp.local.        TXT    IN     20 bytes: 09 74 78 74 76 65 72 73 3D 31 09 70 6F 72 74 3D 34 30 30 30
16:02:18.054  Add     2  8 rpi9._http._tcp.local.        TXT    IN     20 bytes: 09 74 78 74 76 65 72 73 3D 31 09 70 6F 72 74 3D 34 30 30 30
^C
```

We can decipher the data stored in the TXT record with Bash/IEx:

```
$ echo " 09 74 78 74 76 65 72 73 3D 31 09 70 6F 72 74 3D 34 30 30 30" | sed -e 's| |, 0x|g'
, 0x09, 0x74, 0x78, 0x74, 0x76, 0x65, 0x72, 0x73, 0x3D, 0x31, 0x09, 0x70, 0x6F, 0x72, 0x74, 0x3D, 0x34, 0x30, 0x30, 0x30
$ iex
> :string.tokens([ 0x09, 0x74, 0x78, 0x74, 0x76, 0x65, 0x72, 0x73, 0x3D, 0x31, 0x09, 0x70, 0x6F, 0x72, 0x74, 0x3D, 0x34, 0x30, 0x30, 0x30 ], '\t')
['txtvers=1', 'port=4000']
```

Let's confront it with the [TXT record we register in `hello_network`](https://github.com/erszcz/nerves-examples/blob/f788e8b8a0bc73a8646b033d9ef1b3a6e64c890a/hello_network/lib/hello_network.ex#L69-L74):

```elixir
Mdns.Server.add_service(%Mdns.Server.Service{
  domain: "#{hostname}._http._tcp.local",
  data: ["txtvers=1", "port=4000"],
  ttl: 10,
  type: :txt
})
```

Yeah, the `data` got through!
This gives us all the information we need to connect to the service:
the hostname (`rpi9.local`) which we can translate to an IP address with the A
record query, and the port we use directly to connect to a service.


## Objectives

Based on the descriptions in _Introduction_ and the experiments carried out above,
let's set some objectives:

-   We want the `device` app from task #4 to discover when devices join
    and leave the network.
    A device might advertise different service types, not necessarily a web server,
    so the `Device` structure might need extension to accomodate that.
    A domain name (that's a hostname and the `.local` suffix),
    a service type and port seem to be a sensible set of data to store.

-   The device itself should register its presence using mDNS / DNS-SD.
    It should also set up a web interface and advertise the service,
    so that `device` can pick up the registration
    and make it show up in the device list of `webui`.
    Hyperlinking the entries in `webui` would make sense,
    so that we can get to the device's interface with a single click
    (and we get a use case for storing the domain and port).
    The device interface should display the device hostname.
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
