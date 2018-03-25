
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

    modes = ["auto", "manu", "party", "boost"]

    constructor: (@config, @controller) ->
      @name = @config.name
      @id = @config.id
      super()

      @subscription1 = @controller.subscribe(@config.peerId, 0).subscribe((message) =>
        env.logger.debug(@config.peerId, 0, message)
        if message.LOWBAT? then @emit("lowbat", @_lowbat = message.LOWBAT)
      )

      @subscription2 = @controller.subscribe(@config.peerId, 4).subscribe((message) =>
        env.logger.debug(@config.peerId, 4, message)
        if message.CONTROL_MODE? then       @emit("mode", @_mode = modes[message.CONTROL_MODE])
        if message.BATTERY_STATE? then      @emit("battery", @_battery = message.BATTERY_STATE)
        if message.SET_TEMPERATURE? then    @emit("temperatureSetpoint", @_temperatureSetpoint = message.SET_TEMPERATURE)
        if message.ACTUAL_TEMPERATURE? then @emit("temperature", @_temperature = message.ACTUAL_TEMPERATURE)
        if message.VALVE_STATE? then        @emit("valve", @_valve = message.VALVE_STATE)
        @_setSynced(true)
      )

    destroy: () =>
      env.logger.debug('Destroy HomematicThermostat')
      @controller.unsubscribe(@config.peerId, 1)
      @subscription1.unsubscribe()
      @subscription2.unsubscribe()
      super()

    # ####changeTemperatureTo(temperatureSetpoint)
    # The `changeTemperatureTo` function should change the temperatureSetpoint of the thermostat, when called by the
    # framework.
    changeTemperatureTo: (temperatureSetpoint) ->
      # If temperatureSetpoint is aleady set, just return a empty promise
      if @_temperatureSetpoint is temperatureSetpoint then return Promise.resolve()

      @controller.publish(@config.peerId, 4, "SET_TEMPERATURE", temperatureSetpoint).then((temperatureSetpoint) =>
        @emit("temperatureSetpoint", @_temperatureSetpoint = temperatureSetpoint)
      )

    changeModeTo: (mode) ->
      # If mode is aleady set, just return a empty promise
      if @_mode is mode then return Promise.resolve()

      switch mode
        when "auto" then params = ["AUTO_MODE", true]
        when "manu" then params = ["MANU_MODE", @_temperatureSetpoint]
        when "party" then params = ["PARTY_MODE_SUBMIT", true]
        when "boost" then params = ["BOOST_MODE", true]
        else params = ["AUTO_MODE", true]

      return @controller.publish(@config.peerId, 4, params[0], params[1]).then((state) =>
        @emit("mode", @_mode = mode)
      )

    # MQTT publishes the properties on subscription and change
    # so there is no need to request it
    getTemperatureSetpoint: () ->
      return Promise.resolve(@_temperatureSetpoint)

    # MQTT publishes the properties on subscription and change
    # so there is no need to request it
    getTemperature: () ->
      return Promise.resolve(@_temperature)

    # MQTT publishes the properties on subscription and change
    # so there is no need to request it
    getValve: () ->
      return Promise.resolve(@_valve)

    # MQTT publishes the properties on subscription and change
    # so there is no need to request it
    getMode: () ->
      return Promise.resolve(@_mode)

    # MQTT publishes the properties on subscription and change
    # so there is no need to request it
    getBattery: () ->
      return Promise.resolve(@_battery)

    # MQTT publishes the properties on subscription and change
    # so there is no need to request it
    getLowbat: () ->
      return Promise.resolve(@_lowbat)
