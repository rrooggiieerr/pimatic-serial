module.exports = {
  title: "pimatic-serial device config schemas"
  SerialDevice: {
    title: "Serial device config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      serialPort:
        description: "Serialport name (e.g. /dev/ttyUSB0)"
        type: "string"
        default: "/dev/ttyUSB0"
      baudRate:
        description: "Baudrate to use for communicating over serialport (e.g. 9600)"
        type: "integer"
        default: 9600
      dataBits:
        description: "Number of databits to use for communication over serialport (e.g. 7)"
        type: "integer"
        default: 8
      parity:
        description: "Parity to use for communication over serialport (can be 'none', 'even', 'mark', 'odd', 'space')"
        type: "string"
        default: "none"
      stopBits:
        description: "Number of stopBits to use for communication over serialport (can be 1 or 2)"
        type: "integer"
        default: 1
      flowControl:
        description: "Use flowControl for communication over serialport (can be true or false)"
        type: "boolean"
        default: true
      replaceHex:
        description: "Replace Hexadecimal values in the commands with it's binary value (can be true or false)"
        type: "boolean"
        default: false
  }
  SerialSwitch: {
    title: "Serial Switch config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      serialPort:
        description: "Serialport name (e.g. /dev/ttyUSB0)"
        type: "string"
        default: "/dev/ttyUSB0"
      baudRate:
        description: "Baudrate to use for communicating over serialport (e.g. 9600)"
        type: "integer"
        default: 9600
      dataBits:
        description: "Number of databits to use for communication over serialport (e.g. 7)"
        type: "integer"
        default: 8
      parity:
        description: "Parity to use for communication over serialport (can be 'none', 'even', 'mark', 'odd', 'space')"
        type: "string"
        default: "none"
      stopBits:
        description: "Number of stopBits to use for communication over serialport (can be 1 or 2)"
        type: "integer"
        default: 1
      flowControl:
        description: "Use flowControl for communication over serialport (can be true or false)"
        type: "boolean"
        default: true
      onCommand:
        description: "the command to execute to switch the switch on"
        type: "string"
        default: ""
      offCommand:
        description: "the command to execute to switch the switch off"
        type: "string"
        default: ""
      replaceHex:
        description: "Replace Hexadecimal values in the commands with it's binary value (can be true or false)"
        type: "boolean"
        default: false
  }
  SerialShutterController: {
    title: "Serial Shutter Controler config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      serialPort:
        description: "Serialport name (e.g. /dev/ttyUSB0)"
        type: "string"
        default: "/dev/ttyUSB0"
      baudRate:
        description: "Baudrate to use for communicating over serialport (e.g. 9600)"
        type: "integer"
        default: 9600
      dataBits:
        description: "Number of databits to use for communication over serialport (e.g. 7)"
        type: "integer"
        default: 8
      parity:
        description: "Parity to use for communication over serialport (can be 'none', 'even', 'mark', 'odd', 'space')"
        type: "string"
        default: "none"
      stopBits:
        description: "Number of stopBits to use for communication over serialport (can be 1 or 2)"
        type: "integer"
        default: 1
      flowControl:
        description: "Use flowControl for communication over serialport (can be true or false)"
        type: "boolean"
        default: true
      upCommand:
        description: "the command to execute to move the shutter up"
        type: "string"
        default: ""
      downCommand:
        description: "the command to execute to move the shutter down"
        type: "string"
        default: ""
      stopCommand:
        description: "the command to execute to stop the shutter"
        type: "string"
        default: ""
      replaceHex:
        description: "Replace Hexadecimal values in the commands with it's binary value (can be true or false)"
        type: "boolean"
        default: false
  }
}
