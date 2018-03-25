
module.exports = (env) ->

  class HomegearSwitch extends env.devices.PowerSwitch

    attributes:
      state:
        description: "state of the switch"
        type: "boolean"
        labels: ['on', 'off']

    constructor: (@config, @controller) ->
      @name = @config.name
      @id = @config.id
      super()

      @subscription = @controller.subscribe(@config.peerId, 1).subscribe((message) =>
        env.logger.debug(@config.peerId, 1, message)
        if message.STATE? then @emit("state", @_state = message.STATE)
      )

    destroy: () =>
      env.logger.debug('Destroy HomegearSwitch')
      @controller.unsubscribe(@config.peerId, 1)
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
    getState: () ->
      return Promise.resolve(@_state)
