module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  t = env.require('decl-api').types
  fs = env.require 'fs' 

  SerialPort = require 'serialport'
  Readline = SerialPort.parsers.Readline

  class SerialPlugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      @framework.ruleManager.addActionProvider(new SendCommandActionProvider(@framework))

      deviceConfigDef = require('./device-config-schema')
      @framework.deviceManager.registerDeviceClass('SerialDevice', {
        configDef: deviceConfigDef.SerialDevice,
        createCallback: (config, lastState) =>
          device = new SerialDevice(config, lastState)
          return device
      })
      @framework.deviceManager.registerDeviceClass('SerialSwitch', {
        configDef: deviceConfigDef.SerialSwitch,
        createCallback: (config, lastState) =>
          device = new SerialSwitch(config, lastState)
          return device
      })
      @framework.deviceManager.registerDeviceClass('SerialShutterController', {
        configDef: deviceConfigDef.SerialShutterController,
        createCallback: (config, lastState) =>
          device = new SerialShutterController(config, lastState)
          return device
      })

  # Basic serial device, all other serial devices are extended from this one.
  # When defining just a SerialDevice in pimatic the only option you have is to send a command using a rule
  # which might be just enough in some cases.
  class SerialDevice extends env.devices.Device
    parser = null
    port = null

    actions:
      sendCommand:
        description: 'The command to send to the serial device'
        params:
          command:
            type: t.string

    constructor: (config, lastState) ->
      if !@config || Object.keys(@config).length == 0
        @config = config

      @id = @config.id
      @name = @config.name

      @serialPort = if @config.serialPort then @config.serialPort else config.serialPort
      @baudRate = if @config.baudRate then @config.baudRate else config.baudRate
      @dataBits = if @config.dataBits then @config.dataBits else config.dataBits
      @parity = if @config.parity then @config.parity else config.parity
      @stopBits = if @config.stopBits then @config.stopBits else config.stopBits
      @flowControl = if @config.flowControl then @config.flowControl else config.flowControl

      @replaceHex = if @config.replaceHex then @config.replaceHex else config.replaceHex
      @parserDelimiter = if @config.parserDelimiter then @config.parserDelimiter else if config.parserDelimiter then config.parserDelimiter else null
      @parserRegex = if @config.parserRegex then @config.parserRegex else if config.parserRegex then config.parserRegex else null

      # Create the response parser, if any
      if @parserDelimiter
        env.logger.info 'Initialising ReadLine response parser'
        @parser = new SerialPort.parsers.Readline({delimiter: @parserDelimiter})
      else if @parserRegex
        env.logger.info 'Initialising Regex response parser'
        @parser = new SerialPort.parsers.Regex({regex: @parserRegex})

      # If no parser is defined we connect imediately, else we only connect when a message is send
      if @parser
        @_connect()

      super()

    _connect: (callback = null) ->
      env.logger.debug 'Checking if serialport exists'
      fs.realpath @serialPort, (error, resolvedPath) =>
        devices =  SerialPort.list()
        devices.then (_devices) =>
          exists = false
          for _device in _devices
            if _device.comName == resolvedPath
              exists = true
              break

          if !exists
            env.logger.error 'Serial port %s does not exist', @serialPort
          else
            env.logger.debug 'Serial port %s exists', @serialPort

            env.logger.debug 'Creating port'
            @port = SerialPort @serialPort, {
              baudRate: @baudRate,
              dataBits: @dataBits,
              parity: @parity,
              stopBits: @stopBits,
              flowControl: @flowControl,
              autoOpen: true
            }, (error) =>
              if error
                env.logger.error 'Error: %s', error.message
              else
                env.logger.debug 'Port created'

                if @_responseHandler
                  if @parser
                    @port.pipe @parser
                    @parser.on 'data', (data) =>
                      @_responseHandler data
                  else
                    env.logger.info 'No response parser configured, working in write only mode'

                if @_onOpen
                  env.logger.debug 'Executing onOpen'
                  @_onOpen()

                if callback
                  env.logger.debug 'Executing callback'
                  callback()

    _disconnect: (callback) ->
      if @port && @port.isOpen
        env.logger.debug 'Closing port'
        @port.close (error) =>
          if error
            env.logger.error error
          else
            env.logger.debug 'Closed port'
            @port = null
            if callback
              env.logger.debug 'Executing callback'
              callback()
      else
        env.logger.debug 'Port is already closed'
        if callback
          env.logger.debug 'Executing callback'
          callback()

    _write: (data, callback) ->
      env.logger.debug 'Writing data %s', data
      @port.write data, (error) =>
        env.logger.debug 'Data written'
        if error
          env.logger.error error
        else
          @port.drain()
          if !@parser
            @_disconnect () =>
              if callback
                callback()
          else
            if callback
              callback()

    sendCommand: (command) ->
      env.logger.debug 'Sending command %s', command

      env.logger.debug 'Replacing escaped characters'
      command = command.replace /\\./gi, (m) ->
          switch m
            when '\\\\'
              return '\\'
            when '\\n'
              return '\n'
            when '\\r'
              return '\r'
            when '\\t'
              return '\t'
            when '\\v'
              return '\v'
            when '\\b'
              return '\b'
            when '\\f'
              return '\f'
            when "\\'"
              return "'"
            when '\\"'
              return '"'
          return ''

      if @replaceHex
        env.logger.debug 'Replacing hex values'
        command = command.replace(/0x[0-9A-F]{2}/gi, (m) ->
          return String.fromCharCode parseInt(m)
        )
        command = new Buffer command, 'ascii'

      if @port && @port.isOpen
        @_write command, () =>
          env.logger.debug 'Command successfully send'
      else
        @_connect () =>
          @_write command, () =>
            env.logger.debug 'Command successfully send'

    destroy: ->
      @_disconnect()
      super()

  env.devices.SerialDevice = SerialDevice

  class SerialSwitch extends SerialDevice
    _state:null

    actions:
      sendCommand:
        description: 'The command to send to the serial device'
        params:
          command:
            type: t.string
      turnOn:
        description: "Turns the switch on"
      turnOff:
        description: "Turns the switch off"
      changeStateTo:
        description: "Changes the switch to on or off"
        params:
          state:
            type: t.boolean
      toggle:
        description: "Toggle the state of the switch"
      getState:
        description: "Returns the current state of the switch"
        returns:
          state:
            type: t.boolean

    attributes:
     state:
        description: "The current state of the switch"
        type: t.boolean
        labels: ['on', 'off']

    template: "switch"

    constructor: (config, lastState) ->
      if !@config || Object.keys(@config).length == 0
        @config = config
      @onCommand = if @config.onCommand then @config.onCommand else config.onCommand
      @offCommand = if @config.offCommand then @config.offCommand else config.offCommand

      @_state = lastState?.state?.value or off

      super(config, lastState)

    # Returns a promise
    turnOn: -> @changeStateTo on

    # Returns a promise
    turnOff: -> @changeStateTo off

    toggle: ->
      @getState().then( (state) => @changeStateTo(!state) )

    # Returns a promise that is fulfilled when done.
    changeStateTo: (state) ->
      switch state
        when on
          @sendCommand @onCommand
          @_setState state
        when off
          @sendCommand @offCommand
          @_setState state

    # Returns a promise that will be fulfilled with the state
    getState: -> Promise.resolve(@_state)

    _setState: (state) ->
      if @_state is state then return
      @_state = state
      @emit "state", state

  env.devices.SerialSwitch = SerialSwitch

  class SerialShutterController extends SerialDevice
    _position: null

    attributes:
      position:
        label: "Position"
        description: "State of the shutter"
        type: t.string
        enum: ['up', 'down', 'stopped']

    actions:
      sendCommand:
        description: 'The command to send to the serial device'
        params:
          command:
            type: t.string
      moveUp:
        description: "Raise the shutter"
      moveDown:
        description: "Lower the shutter"
      stop:
        description: "Stops the shutter move"
      moveToPosition:
        description: "Changes the shutter state"
        params:
          state:
            type: t.string

    template: "shutter"

    constructor: (config, lastState) ->
      if !@config || Object.keys(@config).length == 0
        @config = config

      @upCommand = if @config.upCommand then @config.upCommand else config.upCommand
      @downCommand = if @config.downCommand then @config.downCommand else config.downCommand
      @stopCommand = if @config.stopCommand then @config.stopCommand else config.stopCommand

      @_position = lastState?.position?.value or 'stopped'

      super(config, lastState)

    # Returns a promise
    moveUp: -> @moveToPosition('up')
    # Returns a promise
    moveDown: -> @moveToPosition('down')

    stop: ->
      @sendCommand @stopCommand

      @_setPosition('stopped')
      return Promise.resolve()

    # Returns a promise that is fulfilled when done.
    moveToPosition: (position) ->
      switch position
        when 'up'
          @sendCommand @upCommand
        when 'down'
          @sendCommand @downCommand

      @_setPosition(position)
      return Promise.resolve()

    # Returns a promise that will be fulfilled with the position
    getPosition: -> Promise.resolve(@_position)

    _setPosition: (position) ->
      assert position in ['up', 'down', 'stopped']
      if @_position is position then return
      @_position = position
      @emit "position", position

    destroy: () ->
      super()

  env.devices.SerialShutterController = SerialShutterController

  _ = require 'lodash' 
  M = env.matcher

  class SendCommandActionProvider extends env.actions.ActionProvider
    constructor: (@framework) ->

    parseAction: (input, context) =>
      # Get all devices which have a send method
      sendDevices = _(@framework.deviceManager.devices).values().filter(
        (device) => device.hasAction('sendCommand')
      ).value()

      device = null
      command = null
      match = null

      # Match action
      # send "<command>" to <device>
      m = M(input, context)
        .match('send ')
        .match('command ', optional: yes)
        .matchStringWithVars((m, _command) ->
          m.match(' to ')
            .matchDevice(sendDevices, (m, _device) ->
              device = _device
              command = _command
              match =  m.getFullMatch()
            )
        )

      # Does the action match with our syntax?
      if match?
        assert device?
        assert command?
        assert typeof match is 'string'
        return {
          token: match
          nextInput: input.substring match.length
          actionHandler: new SendCommandActionHandler @framework, device, command
        }
      return null
      
  class SendCommandActionHandler extends env.actions.ActionHandler
    constructor: (@framework, @device, @command) ->

    executeAction: (simulate) ->
      return (
        @framework.variableManager.evaluateStringExpression(@command).then((command) =>
          if simulate
            Promise.resolve __('would send command %s to %s', command, @device.name)
          else
            @device.sendCommand command
            Promise.resolve __('sended command %s to %s', command, @device.name)
          )
      )

  return new SerialPlugin
