--
-- Created by IntelliJ IDEA.
-- User: matt
-- Date: 28/10/17
-- Time: 10:41 AM
-- To change this template use File | Settings | File Templates.
--
local tcp = require("tcp_client")
local at = require("at_commands")
local MQTT = require("mqtt_library")
local logging = require("logging")
local config = require("config")
local logger = logging.create("mqtt_thread", 30)

local _M = {}

local data_handler = function(topic, message)
    logger(30, "Topic: " .. topic .. ", message: '" .. message .. "'")
end

local mqtt_thread = function()
    local SOCK_RST_OK = 0
    local SOCK_RST_SOCK_FAILED = 4

    while( true ) do
        logger(0, "Set debug true")
        MQTT.Utility.set_debug(true)
        logger(0, "Set keepalive")
        MQTT.client.KEEP_ALIVE_TIME = 30
        logger(0, "client create")
        local mqtt_client = MQTT.client.create(config.get_config_value("MQ_HOST"), config.get_config_value("MQ_PORT"), data_handler)
        logger(0, "connect")
        local connect_result = mqtt_client:connect("testclientid")
        logger(0, "Connect result was: ", tostring(connect_result))
        logger(0, "subscribe")
        mqtt_client:subscribe({"testclientid/topic/data"})

        local error_message
        while (error_message == nil) do
            logger(0, "Into handler\r\n")
          error_message = mqtt_client:handler()
        end
        thread.sleep(10000)
    end

end
_M.mqtt_thread = mqtt_thread


return _M
