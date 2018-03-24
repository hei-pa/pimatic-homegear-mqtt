
module.exports = (env) ->

  class HomegearThermostat extends env.devices.HeatingThermostat

    attributes:
      temperatureSetpoint:
        label: "Temperature Setpoint"
        description: "The temp that should be set"
        type: "number"
        discrete: true
        unit: "°C"
      temperature:
        label: "Actual Temperature"
        description: "The actual temperature"
        type: "number"
        discrete: true
        unit: "°C"
      valve:
        description: "Position of the valve"
        type: "number"
        discrete: true
        unit: "%"
      mode:
        description: "The current mode"
        type: "string"
        enum: ["auto", "manu", "boost"]
      battery:
        description: "Battery Voltage"
        type: "number"
        discrete: true
        unit: "V"
      lowbat:
        description: "Low Battery Voltage"
        type: "boolean"
        labels: ['yes', 'no']
      synced:
        description: "Pimatic and thermostat in sync"
        type: "boolean"

    actions:
      changeModeTo:
        params:
          mode:
            type: "string"
      changeTemperatureTo:
        params:
          temperatureSetpoint:
            type: "number"

    template: "thermostat"

    constructor: (@config, @controller) ->
      @name = @config.name
      @id = @config.id
      super()

      @subscription = @controller.subscribe(@config.peerId, 0).subscribe((message) =>
        env.logger.debug(@config.peerId, 0, message)
        if message.LOWBAT? then @emit("lowbat", @_lowbat = message.LOWBAT)
      )

      @subscription = @controller.subscribe(@config.peerId, 4).subscribe((message) =>
        env.logger.debug(@config.peerId, 4, message)
        if message.CONTROL_MODE? then       @emit("mode", @_mode = @convertStateMode(message.CONTROL_MODE))
        if message.BATTERY_STATE? then      @emit("battery", @_battery = message.BATTERY_STATE)
        if message.SET_TEMPERATURE? then    @emit("temperatureSetpoint", @_temperatureSetpoint = message.SET_TEMPERATURE)
        if message.ACTUAL_TEMPERATURE? then @emit("temperature", @_temperature = message.ACTUAL_TEMPERATURE)
        if message.VALVE_STATE? then        @emit("valve", @_valve = message.VALVE_STATE)
        @_setSynced(true)
      )

    destroy: () =>
      env.logger.debug('Destroy HomematicThermostat')
      @controller.unsubscribe(@config.peerId, 1)
      @subscription.unsubscribe()
      super()

    convertStateMode: (state) =>
      switch state
        when 0 then return "auto"
        when 1 then return "manu"
        when 2 then return "party"
        when 3 then return "boost"

    convertModeState: (mode) =>
      switch mode
        when "auto" then return 0
        when "manu" then return 1
        when "party" then return 2
        when "boost" then return 3

    # ####changeTemperatureTo(temperatureSetpoint)
    # The `changeTemperatureTo` function should change the temperatureSetpoint of the thermostat, when called by the
    # framework.
    changeTemperatureTo: (temperatureSetpoint) ->
      # If temperatureSetpoint is aleady set, just return a empty promise
      if @_temperatureSetpoint is temperatureSetpoint then return Promise.resolve()

      @controller.publish(@config.peerId, 1, "SET_TEMPERATURE", temperatureSetpoint).then((temperatureSetpoint) =>
        @emit("temperatureSetpoint", @_temperatureSetpoint = temperatureSetpoint)
      )

    changeModeTo: (mode) ->
      # If mode is aleady set, just return a empty promise
      if @_mode is mode then return Promise.resolve()

      @controller.publish(@config.peerId, 1, "CONTROL_MODE", @convertModeState(mode)).then((state) =>
        @emit("mode", @_mode = mode)
      )

    # MQTT publishes the properties on subscription and change
    # so there is no need to request it
    getTemperatureSetpoint: () ->
      return Promise.resolve(@_temperatureSetpoint)

    getTemperature: () ->
      return Promise.resolve(@_temperature)

    getValve: () ->
      return Promise.resolve(@_valve)

    getMode: () ->
      return Promise.resolve(@_mode)

    getBattery: () ->
      return Promise.resolve(@_battery)

    getLowbat: () ->
      return Promise.resolve(@_lowbat)
