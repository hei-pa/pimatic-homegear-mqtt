# #Plugin template

# This is an plugin template and mini tutorial for creating pimatic plugins. It will explain the
# basics of how the plugin system works and how a plugin should look like.

# ##The plugin code

# Your plugin must export a single function, that takes one argument and returns a instance of
# your plugin class. The parameter is an envirement object containing all pimatic related functions
# and classes. See the [startup.coffee](http://sweetpi.de/pimatic/docs/startup.html) for details.
module.exports = (env) ->

  # ###require modules included in pimatic
  # To require modules that are included in pimatic use `env.require`. For available packages take
  # a look at the dependencies section in pimatics package.json

  # Require the bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  # Include you own depencies with nodes global require function:
  #
  #     someThing = require 'someThing'
  #
  mqtt = require('mqtt')
  Rx = require('rxjs')

  class MqttController

    connect: (@mqttHost, @mqttId) ->
      @mqttClient = mqtt.connect('mqtt://' + @mqttHost)

      @receiver = Rx.Observable.fromEvent(@mqttClient, "message", (topic, message) => ({topic, message: JSON.parse(message)}))

      @mqttClient.on('connect', =>
        env.logger.info("Connected to MQTT Broker #{@mqttHost}")
      )

      @mqttClient.on('error', (error) =>
        env.logger.error(error)
      )

    publish: (id, group, property, value) =>
      topic = "homegear/#{@mqttId}/set/#{id}/#{group}/#{property}"
      return new Promise((resolve, reject) =>
        @mqttClient.publish(topic, value.toString(), null, (err) =>
          if err then reject()
          resolve(value)
        )
      )


    subscribe: (id, group) =>
      topic = "homegear/#{@mqttId}/jsonobj/#{id}/#{group}"
      env.logger.debug("Subscribing to #{topic}")
      @mqttClient.subscribe(topic)
      return @receiver.filter((event) =>
        return event.topic == topic
      ).map((event) =>
        return event.message
      )

    unsubscribe: (id, group) =>
      @mqttClient.unsubscribe("homegear/#{@mqttId}/jsonobj/#{id}/#{group}")

  HomegearSwitch = require('./devices/homegear-switch')(env)
  HomegearPowerSwitch = require('./devices/homegear-power-switch')(env)
  HomematicThermostat = require('./devices/homegear-thermostat')(env)

  # ###HomegearMqtt class
  # Create a class that extends the Plugin class and implements the following functions:
  class HomegearMqtt extends env.plugins.Plugin

    # ####init()
    # The `init` function is called by the framework to ask your plugin to initialise.
    #
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins`
    #     section of the config.json file
    #
    #
    init: (app, @framework, @config) =>
      env.logger.info("Homegear MQTT")

      controller = new MqttController
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("HomegearSwitch", {
        configDef: deviceConfigDef.HomegearSwitch
        createCallback: (config) => new HomegearSwitch(config, controller)
      })

      @framework.deviceManager.registerDeviceClass("HomegearPowerSwitch", {
        configDef: deviceConfigDef.HomegearPowerSwitch
        createCallback: (config) => new HomegearPowerSwitch(config, controller)
      })

      @framework.deviceManager.registerDeviceClass("HomematicThermostat", {
        configDef: deviceConfigDef.HomematicThermostat
        createCallback: (config) => new HomematicThermostat(config, controller)
      })

      controller.connect(@config.host, @config.id)

  # ###Finally
  # Create a instance of HomegearMqtt
  homegearMqtt = new HomegearMqtt
  # and return it to the framework.
  return homegearMqtt
