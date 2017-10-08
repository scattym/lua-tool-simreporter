local _M = {}

json = require("json")
logger = require("logging")
tcp = require("tcp_client")

local CONFIG ={}
-- Time to sleep between successive nmea reports
CONFIG["NMEA_SLEEP_TIME"] = 30000
-- Report GPS at this interval. Turns off GPS in between
CONFIG["REPORT_INTERVAL"] = 3600000
-- Number of NMEA reports to send every REPORT_INTERVAL, set to 0 for infinite
CONFIG["NMEA_LOOP_COUNT"] = 100
CONFIG["MAIN_THREAD_SLEEP"] = 5000
-- Number of times to run main thread before exiting, set to 0 for infinite
CONFIG["MAX_MAIN_THREAD_LOOP_COUNT"] = 0
CONFIG["GPS_LOCK_CHECK_SLEEP_TIME"] = 20000
CONFIG["GPS_LOCK_CHECK_MAX_LOOP"] = 50
CONFIG["FIRMWARE_SLEEP_TIME"] = 3600000
CONFIG["CELL_THREAD_SLEEP_TIME"] = 7200000
CONFIG["MIN_REPORT_TIME"] = 7195
CONFIG["UPDATE_HOST"] = "home.scattym.com"
CONFIG["UPDATE_PORT"] = 65535
CONFIG["CELL_PATH"] = "/v2/process_cell_update"
CONFIG["GPS_PATH"] = "/v2/process_update"
CONFIG["CONFIG_SLEEP_TIME"] = 30000

local client_id = 4
logger.create_logger("config", 30)

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
    "UPDATE_PORT",
    "CONFIG_SLEEP_TIME"
}

local MUST_BE_STRING = {
    "CELL_PATH",
    "UPDATE_HOST",
    "GPS_PATH",
    "checksum"
}

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
            logger.log("config", 0, "Updating hash with key: ", tostring(key), " and value: ", config_table[key])
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

local update_config_checksum = function()
    thread.enter_cs(4);
    CONFIG["checksum"] = calc_checksum(CONFIG)
    thread.leave_cs(4)
    logger.log("config", 0, "New checksum is ", CONFIG["checksum"])
end


local check_value_type = function(key, value)
    for _, field in ipairs(MUST_BE_INTS) do
        if string.equal(field, key) then
            if type(value) == "number" then
                return true
            end
        end
    end
    for _, field in ipairs(MUST_BE_STRING) do
        if string.equal(field, key) then
            if type(value) == "string" then
                return true
            end
        end
    end
    logger.log("config", 30, "No type found for key: ", key, ". assuming correct")
    return true
end

local get_config_value = function(key)
    logger.log("config", 0, "Asking for key: ", key, " return value: ", CONFIG[key])
    thread.enter_cs(4);
    local ret_val = CONFIG[key]
    thread.leave_cs(4);
    return ret_val
end
_M.get_config_value = get_config_value

local set_config_value = function(key, value)
    logger.log("config", 0, "Setting key: ", key, " to be: ", value, " with type: ", type(value))
    if not check_value_type(key, value) then
        logger.log("config", 30, "Type for key: ", key, " with value: ", value, " incorrect as it is a ", type(value))
        return false
    end
    thread.enter_cs(4);
    CONFIG[key] = value
    logger.log("config", 0, "Finished set config value.")
    thread.leave_cs(4)
    return true
end
_M.set_config_value = set_config_value

local set_config_from_table = function(config_table)
    for key, value in pairs(config_table) do
        set_config_value(key, value, false)
    end
    update_config_checksum()
end
_M.set_config_from_table = set_config_from_table


local check_hmac_config = function(config_table)
    local table_checksum = calc_checksum(config_table)
    logger.log("config", 0, "Comparing checksum ", table_checksum, " to advertised checksum of ", config_table["checksum"])
    local advertised_checksum = config_table["checksum"]
    if advertised_checksum and string.equal(table_checksum, advertised_checksum) then
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
        logger.log("config", 30, "Unable to load json from string")
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
    if not file then
        logger.log("config", 30, "Unable to open config file for writing")
    else
        -- file:trunc(0)
        -- Checksum should always be correct, could remove the following
        checksum = calc_checksum(CONFIG)
        set_config_value("checksum", checksum, false)
        local result = file:write(json.encode(CONFIG))
        logger.log("config", 0, "Config file write result: ", result)
        file:close()
        collectgarbage()
        return result
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

local load_config_from_server = function(imei, version)
    local fn_result = false
    --local open_net_result = tcp.open_network(client_id);
    --logger.log("config", 0, "Open network response is: ", open_net_result);
    local result, headers, response = tcp.http_open_send_close(client_id, get_config_value("UPDATE_HOST"), get_config_value("UPDATE_PORT"), "/get_config?ident=imei:" .. imei .. "&version=" .. version .. "&type=5300");
    if( not result or not string.equal(headers["response_code"], "200") ) then
        logger.log("config", 30, "Callout for config failed. Result was: ", result, " and response code: ", headers["response_code"])
    else
        logger.log("config", 0, "Response length is ", #response)
        local old_checksum = get_config_value("checksum")
        fn_result = set_config_from_json(response)
        logger.log("config", 0, "Set config from json result is: ", fn_result)
        if fn_result then
            if old_checksum and string.equal(old_checksum , get_config_value("checksum")) then
                logger.log("config", 0, "Old config same as new config. Not writing to disk.")
            else
                logger.log("config", 0, "Config has changed, writing to disk.")
                local save_result = save_config_to_file()
                logger.log("config", 0, "Save config to file result is: ", save_result)
            end
        end
    end
    collectgarbage();
    logger.log("config", 0, "Overall config load result is: ", fn_result)
    return fn_result
end
_M.load_config_from_server = load_config_from_server

local dump_config = function()
    for key, value in pairs(CONFIG) do
        logger.log("config", 30, "Key: ", key, " and value: ", value)
    end
end
_M.dump_config = dump_config

return _M