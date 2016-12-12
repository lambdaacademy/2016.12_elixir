defmodule Device.Registry do

  def list do
    [
      %Device{
        name: "rpi1",
        domain: "rpi1.local",
        data: "port=8123"
      },
      %Device{
        name: "rpi2",
        domain: "rpi2.local",
        data: "port=4789"
      }
    ]
  end

end
