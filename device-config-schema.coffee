# #homegear-mqtt device configuration options
module.exports = {
  title: "Homegear mqtt device config"
  HomegearSwitch:
    title: "HomegearSwitch"
    type: "object"
    properties:
      peerId:
        description: "Homegear Device Id"
        type: "number"
  HomegearPowerSwitch:
    title: "HomegearPowerSwitch"
    type: "object"
    properties:
      peerId:
        description: "Homegear Device Id"
        type: "number"
  HomematicThermostat: {
    title: "HomematicThermostat"
    type: "object"
    properties:
      peerId:
        description: "The Device PeerID"
        type: "number"
        default: 1
      guiShowModeControl:
        description: "Show the mode buttons in the gui"
        type: "boolean"
        default: true
      guiShowPresetControl:
        description: "Show the preset temperatures in the gui"
        type: "boolean"
        default: false
      guiShowTemperatureInput:
        description: "Show the temperature input spinbox in the gui"
        type: "boolean"
        default: true
  }
}
