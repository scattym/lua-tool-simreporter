local _M = {}

json = require("json")
logger = require("logging")
local CONFIG ={}
-- Time to sleep between successive nmea reports
CONFIG["NMEA_SLEEP_TIME"] = 30000
-- Report GPS at this interval. Turns off GPS in between
CONFIG["REPORT_INTERVAL"] = 3600000
-- Number of NMEA reports to send every REPORT_INTERVAL, set to 0 for infinite
CONFIG["NMEA_LOOP_COUNT"] = 5
CONFIG["MAIN_THREAD_SLEEP"] = 600000
-- Number of times to run main thread before exiting, set to 0 for infinite
CONFIG["MAX_MAIN_THREAD_LOOP_COUNT"] = 0
CONFIG["GPS_LOCK_CHECK_SLEEP_TIME"] = 20000
CONFIG["GPS_LOCK_CHECK_MAX_LOOP"] = 50
CONFIG["FIRMWARE_SLEEP_TIME"] = 3600000
CONFIG["CELL_THREAD_SLEEP_TIME"] = 7200000
CONFIG["MIN_REPORT_TIME"] = 7195
CONFIG["UPDATE_HOST"] = "home.scattym.com"
CONFIG["UPDATE_PORT"] = 65535

local MUST_BE_INTS = {
    "NMEA_SLEEP_TIME",
    "REPORT_INTERVAL",
    "NMEA_LOOP_COUNT",
    "MAIN_THREAD_SLEEP",
    "MAX_MAIN_THREAD_LOOP_COUNT",
    "GPS_LOCK_CHECK_SLEEP_TIME",
    "GPS_LOCK_CHECK_MAX_LOOP",
    "FIRMWARE_SLEEP_TIME",
    "CELL_THREAD_SLEEP_TIME",
    "MIN_REPORT_TIME",
    "UPDATE_PORT"
}

local check_if_should_be_int = function(key)
    for _, field in ipairs(MUST_BE_INTS) do
        if string.equal(field, key) then
            return true
        end
    end
    return false
end

local get_config_value = function(key)
    return CONFIG[key]
end
_M.get_config_value = get_config_value

local set_config_value = function(key, value)
    if check_if_should_be_int(key) then
        if type(value) ~= "number" then
            logger.log("config", 0, key, " must be an integer, but is ", type(value), ". Ignoring")
            return false
        end
    end
    CONFIG[key] = value
    return true
end
_M.set_config_value = set_config_value

local set_config_from_table = function(config_table)
    for key, value in pairs(config_table) do
        set_config_value(key, value)
    end
end
_M.set_config_from_table = set_config_from_table

local function tohex(data)
    return (data:gsub(".", function (x)
        return ("%02x"):format(x:byte()) end)
    )
end

local calc_checksum = function(config_table)
    local temp_table = {}
    for n in pairs(config_table) do table.insert(temp_table, n) end
    table.sort(temp_table)
    local input = "Please press enter:"
    local hash = sha256.init()
    hash:update(input)

    for i,key in ipairs(temp_table) do
        if not string.equal("checksum", key) then
            logger.log("config", 0, "Updating with key: ", tostring(key), " and value: ", config_table[key])
            hash:update(tostring(key))
            hash:update(tostring(config_table[key]))
        end
    end
    hash:update(input)
    local checksum = hash:final()
    local checksum_hex = tohex(checksum)
    collectgarbage()
    return checksum_hex
end

local check_hmac_config = function(config_table)
    table_checksum = calc_checksum(config_table)
    logger.log("config", 0, "Comparing checksum ", table_checksum, " to advertised checksum of ", config_table["checksum"])
    if config_table["checksum"] and string.equal(table_checksum, config_table["checksum"]) then
        logger.log("config", 0, "Checksums are equal")
        return true
    end
    logger.log("config", 0, "Checksum check failed")
    return false
end

local set_config_from_json = function(json_str)
    logger.log("config", 0, "Setting config from json")
    config_table = json.decode(json_str)
    if not config_table then
        logger.log("config", 0, "Unable to load json from string")
        return false
    end
    if check_hmac_config(config_table) then
        logger.log("config", 0, "Passed hmac test, setting config")
        set_config_from_table(config_table)
        return true
    end
    return false
end
_M.set_config_from_json = set_config_from_json

local save_config_to_file = function()
    file = io.open("c:/config.json","w")
    if file then
        -- file:trunc(0)
        checksum = calc_checksum(CONFIG)
        set_config_value("checksum", checksum)
        result = file:write(json.encode(CONFIG))
        logger.log("config", 0, "Config file write result: ", result)
        file:close()
        collectgarbage()
        return true
    end
    collectgarbage()
    return false
end
_M.save_config_to_file = save_config_to_file

local load_config_from_file = function()
    logger.log("config", 0, "Starting config load")
    local file = io.open("c:/config.json","r")
    logger.log("config", 0, "File open attempt finished")
    if not file then
        logger.log("config", 0, "Unable to load config file, not present or not readable")
        return false
    end
    local content = file:read("*all")
    logger.log("config", 0, "Config file content is ", content, "<")
    local set_config_result = set_config_from_json(content)
    logger.log("config", 0, "Set config result is ", set_config_result)
    collectgarbage()
    return set_config_result
end
_M.load_config_from_file = load_config_from_file

return _M