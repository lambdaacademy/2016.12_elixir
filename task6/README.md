# Task 6: Real-time Discovery w/ Phoenix Channels

In this task we're going to provide real-time updates to the web-based
interface displaying the list of devices available in our network.


### What devices are up?

Let's start from a known working state.
If you have a local copy of the school task repository you can just do:

```
git fetch origin
git checkout task6
```

If you want to start from scratch:

```
git clone https://github.com/lambdaacademy/2016.12_elixir.git
cd 2016.12_elixir/task4/iot/apps/webui/
git checkout task6
mix deps.get
mix deps.compile
npm install
mix compile
iex --sname webui -S mix phoenix.server
```

When you plug in the power cable to your device, wait a while and load
[http://localhost:4000/devices](http://localhost:4000/devices) in your browser
you should see the list of devices in the local network with yours in the list.

Each time we turn a device on or off, we have to reload the page.
Let's make the device list update automatically.


### Communicating via channels

[Phoenix tutorial on Channels](http://www.phoenixframework.org/docs/channels)
provides an introduction to the idea, while
[Tying It All Together](http://www.phoenixframework.org/docs/channels#section-tying-it-all-together)
therein gives some examples on how to write a simple channel.
Follow the examples along, but keep the following in mind:

- use `device:__index__` for the channel that device presence updates will be pushed on
- when you're registering callbacks on the client side,
  don't register anything for `keypress`
- instead of a single `new_msg` callback, register two for `add_device` and
  `remove_device` - initially they can just print something to the browser console
  or just render a message in the website

At this point we should be able to launch the webapp in Elixir shell and
push an event to a connected browser:

```
$ iex --sname webui -S mix phoenix.server
```

The browser console should print:

```
GET http://localhost:4000/socket/websocket [HTTP/1.1 101 Switching Protocols 59ms]
Joined successfully Object {  }
```

Let's publish an event from IEx:

```
> Webui.Endpoint.broadcast!("device:__index__", "add_device", %{fake: :payload})
```

The cool thing is that whatever map we send this way to the client will arrive
as a JSON object in the browser - no manual serialization required!
The browser should print:

```
add_device  Object { fake: "payload" }
```

Cool! Channel communication with the browser is in place.


### Broadcasting add/remove events to channels

When the list of devices was refreshed by a page reload,
the event causing our app to render devices came from the browser.
We want to inverse this, i.e. we need some source of events in our
system that will initiate sending a notification to the client's browser.
Our current list of devices is kept by `Device.Registry` which actually
receives notifications and accumulates them to provide a _current_ view of
the network.
Extend `Device.Registry` so that processes can subscribe to it
for `add_device` and `remove_device` events.
The fastest way is to extend the functions we pass to Agent
to send a number of messages for each event the registry processes,
but it's a bit clunky as it won't clean up subscribers that might've died.
Another way is to make it a proper GenServer monitoring the subscribers
and receiving `DOWN` signals appropriately.

Once `Device.Registry` can notify subscribers, we need a process in
`webui` which will subscribe and receive these notifications.
This way the direction of dependency is kept intact:
`webui` depends on `device` (subscribes to one of its processes),
but `device` is oblivious of `webui`.
Let's call this process `Webui.DeviceListener`.
It should `Webui.Endpoint.broadcast!/3` each event it
receives from `Device.Registry.
Here we have another piece of the puzzle - the browser now receives
information about devices (dis)appearing in the network.
However, this information is in JSON - we have to render it
from JavaScript on the client side.


### Rendering on the client side

We'd like to be able to follow links to HTTP services advertised on the network.
Fortunately, such services have type `_http._tcp`, so it's easy to
recognize them on the client side.
In case of other services, a simple text item is sufficient.

For the sake of this exercise we'll only use a couple of basic functions
for "manual" rendering the device services, namely:

- `Document.querySelector` / `Document.getElementById`
- `Document.createElement`
- `Element.setAttribute`
- `Node.innerText`
- `Node.appendChild` / `Node.removeChild`

They're all documented on
[Mozilla Developer Network](https://developer.mozilla.org/en-US/docs/Web/API).
