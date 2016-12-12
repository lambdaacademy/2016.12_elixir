# Task 4: Device discovery


## mDNS Service Discovery

mDNS allows us to register services in a distributed fashion.
Let's see how to do it from Elixir.

First, let's use a pregenerated project which depends on an mDNS library:

```sh
cd task4/iot/apps/device
mix deps.get
mix compile
iex -S mix
```

Once we're in the Elixir shell, let's register an HTTP server:

```elixir
iex> :dnssd.start()
iex> :dnssd.register("_http._tcp", 8123)
iex> flush
{:ok, #Reference<0.0.2.1230>}
```

Let's open one more `iex`:

```elixir
iex> :dnssd.start
iex> :dnssd.browse("_http._tcp")
{:ok, #Reference<0.0.4.117>}
iex> flush
{:dnssd, #Reference<0.0.4.117>,
 {:browse, :add, {"x4", "_http._tcp.", "local."}}}
:ok
iex> :dnssd.resolve_sync("x4", "_http._tcp", "local.")
{:ok, {"x4.local.", 8123, [""]}}
```

Based on the example above we can discover HTTP services running in the local network.
We'll use this to discover devices and enable access to them from Elixir / Erlang systems.


## Phoenix WebUI for device discovery

`task4/iot/apps/webui` contains a skeleton application for displaying discovered devices.
Follow the [_Up and Running_ Phoenix guide][phoenix:up-and-running] to see how
it's built from scratch.
Right now the application lists a mocked list of devices.

Extend `Device.Registry` to an Agent which encapsulates the list
of currently discovered devices.
Add `Device.Scanner` which will be a GenServer scanning the network
and adding new devices to the registry as they are discovered.


## Appendix: How to tell the BSSID of an access point?

You might not be able to discover a device with mDNS if it's connected
to a different WiFi access point (although the same WiFi network! i.e. same SSID)
than you are.
The identifier of an access point is called BSSID and it's its MAC address.

To tell the BSSID of an access point on Linux (at least Ubuntu):

```
sudo iwlist scanning | grep Address
```

On macOS find `airport` (the location will vary between system versions):

```
$ find /System/Library/PrivateFrameworks/Apple80211.framework/ -name airport
/System/Library/PrivateFrameworks/Apple80211.framework//Versions/A/Resources/airport
```

Get the BSSID:

```
$ /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | grep BSSID
```


## Further reading

- [Phoenix Framework: Installation](http://www.phoenixframework.org/docs/installation)
- [Phoenix Framework: Up and Running][phoenix:up-and-running]
- [How to show the BSSID of an access point? Linux](http://askubuntu.com/questions/40068/show-bssid-of-an-access-point/40070)
- [How to show the BSSID of an access point? macOS](http://osxdaily.com/2007/01/18/airport-the-little-known-command-line-wireless-utility/)

[phoenix:up-and-running]: http://www.phoenixframework.org/docs/up-and-running
