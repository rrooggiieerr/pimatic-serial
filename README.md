pimatic-serial
=================

Pimatic Plugin that supports sending commands to Serial devices.

Configuration
-------------

Add the plugin to the plugin section:

```
    {
      "plugin": "serial"
    },
```

Then add the device entry for your device into the devices section:

```
    {
      "id": "serial-device",
      "class": "SerialDevice",
      "name": "Serial Device",
      "serialport": "/dev/ttyUSB0",
      "baudRate" : 9600,
      "dataBits" : 8,
      "parity" : "none",
      "stopBits" : 1,
      "flowControl" : true
    }
```

Then you can add the items into the mobile frontend
# pimatic-serial
