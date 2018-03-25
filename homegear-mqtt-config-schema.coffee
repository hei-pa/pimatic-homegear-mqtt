# #homegear-mqtt plugin configuration options
module.exports = {
  title: "Homegear mqtt plugin config"
  type: "object"
  properties:
    host:
      description: "MQTT Host"
      type: "string"
      default: "localhost"
    id:
      description: "MQTT Target Id (homegearId)"
      type: "string"
      default: "1234-5678-9abc"
    timeout:
      description: "MQTT Message Response Timeout [s]"
      type: "number"
      default: 10
    debug:
      description: "Output debug messages"
      type: "boolean"
      default: false
}
