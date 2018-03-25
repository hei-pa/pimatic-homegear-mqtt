
module.exports = (env) ->

  class HomegearPowerSwitch extends env.devices.PowerSwitch

    attributes:
      state:
        description: "state of the switch"
        type: "boolean"
        labels: ['on', 'off']
      power:
        description: "power of the switch"
        type: "number"
        unit: "W"
      current:
        description: "current of the switch"
        type: "number"
        unit: "A"
      voltage:
        description: "voltage of the switch"
        type: "number"
        unit: "V"
      frequency:
        description: "frequency of the switch"
        type: "number"
        unit: "Hz"
      energy:
        description: "energy counter of the switch"
        type: "number"
        unit: "kWh"

    constructor: (@config, @controller) ->
      @name = @config.name
      @id = @config.id
      super()

      @subscription = @controller.subscribe(@config.peerId, 1).subscribe((message) =>
        env.logger.debug(@config.peerId, 1, message)
        if message.STATE? then          @emit("state", @_state = message.STATE)
      )

      @subscription = @controller.subscribe(@config.peerId, 2).subscribe((message) =>
        env.logger.debug(@config.peerId, 2, message)
        if message.CURRENT? then         @emit("current", @_current = (message.CURRENT / 1000))
        if message.VOLTAGE? then         @emit("voltage", @_voltage = message.VOLTAGE)
        if message.FREQUENCY? then       @emit("frequency", @_frequency = message.FREQUENCY)
        if message.ENERGY_COUNTER? then  @emit("energy", @_energy = message.ENERGY_COUNTER)
        if message.POWER? then           @emit("power", @_power = message.POWER)
      )

    destroy: () =>
      env.logger.debug('Destroy HomegearPowerSwitch')
      @controller.unsubscribe(@config.peerId, 1)
      @controller.unsubscribe(@config.peerId, 2)
      @subscription.unsubscribe()
      super()

    # ####changeStateTo(state)
    # The `changeStateTo` function should change the state of the switch, when called by the
    # framework.
    changeStateTo: (state) ->
      # If state is aleady set, just return a empty promise
      if @_state is state then return Promise.resolve()

      return @controller.publish(@config.peerId, 1, "STATE", state).then((state) =>
        @emit("state", @_state = state)
      )

    # MQTT publishes the properties on subscription and change
    # so there is no need to request it
    getCurrent: () ->
      return Promise.resolve(@_current)

    getVoltage: () ->
      return Promise.resolve(@_voltage)

    getFrequency: () ->
      return Promise.resolve(@_frequency)

    getEnergy: () ->
      return Promise.resolve(@_energy)

    getPower: () ->
      return Promise.resolve(@_power)

    getState: () ->
      return Promise.resolve(@_state)
