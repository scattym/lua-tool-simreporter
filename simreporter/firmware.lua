--
-- Created by IntelliJ IDEA.
-- User: matt
-- Date: 12/9/17
-- Time: 5:21 PM
-- To change this template use File | Settings | File Templates.
--

local _M = {}

local http_lib = require("http_lib")
local unzip = require("unzip")
local at = require("at_commands")
local json = require("json")
local logger = require("logging")
local config = require("config")
local client_id = 3
local NET_CLIENT_ID_FIRMWARE = config.get_config_value("NET_CLIENT_ID_FIRMWARE")

local function tohex(data)
    return (data:gsub(".", function (x)
        return ("%02x"):format(x:byte()) end)
    )
end

logger.create_logger("firmware", 30)

function get_firmware(imei, version)
    local fn_result = false

    collectgarbage()

    local result, headers, response = http_lib.http_connect_send_close(NET_CLIENT_ID_FIRMWARE, config.get_config_value("FIRMWARE_HOST"), config.get_config_value("UPDATE_PORT"), "/get_firmware?ident=imei:" .. imei, "");
    collectgarbage()
    if( not result or not string.equal(headers["response_code"], "200") ) then
        logger.log("firmware", 30, "Callout for firmware failed. Result was: ", result, " and response code: ", headers["response_code"])
    else
        logger.log("firmware", 10, "Response length is ", #response)
        local firmware_json = json.decode(response);
        collectgarbage()

        logger.log("firmware", 10, firmware_json);
        if not firmware_json then
            logger.log("firmware", 30, "Unable to load firmware json")
        elseif( is_version_quarantined(firmware_json["version"]) ) then
            logger.log("firmware", 30, "Version ", firmware_json["version"], " is already quarantined, not expanding")
        else
            if( firmware_json["version"] and firmware_json["file"] and firmware_json["checksum"] ) then
                logger.log("firmware", 10, firmware_json["version"]);
                logger.log("firmware", 10, "File length: ", tostring(#firmware_json["file"]));
                logger.log("firmware", 10, "Advertised checksum: ", tostring(firmware_json["checksum"]))
                raw_data = base64.decode(firmware_json["file"])
                collectgarbage()
                hash = sha256.init()
                hash:update(raw_data)
                checksum = hash:final()
                checksum_hex = tohex(checksum)
                collectgarbage()
                if( not string.equal(checksum_hex, firmware_json["checksum"]) ) then
                    logger.log("firmware", 30, "Checksums do not match. Calculated checksum is: ", checksum_hex, " but should be: ", firmware_json["checksum"])
                else
                    if( raw_data ) then
                        local zip_file_name = "c:/" .. firmware_json["version"] .. ".zip"
                        file = io.open(zip_file_name,"w") assert(file)
                        file:write(raw_data, "\n")
                        file:close()
                        unzip_result = unzip.unzip_file(zip_file_name, "c:/libs/" .. firmware_json["version"] .. "/")
                        fn_result = unzip_result
                        logger.log("firmware", 10, "Result of unzip is: ", unzip_result)
                        os.delfile(zip_file_name)
                        collectgarbage()
                    end
                end
            else
                logger.log("firmware", 30, "One of the fields is missing. version: ", tostring(firmware_json["version"]), " file: ", tostring(#firmware_json["file"]), " checksum: ", tostring(firmware_json["checksum"]) )
            end
        end
    end
    collectgarbage();
    return fn_result
end

local check_firmware_and_maybe_update = function(imei, current_version)

    local result, headers, response = http_lib.http_connect_send_close(NET_CLIENT_ID_FIRMWARE, config.get_config_value("FIRMWARE_HOST"), 65535, "/get_firmware_version?ident=imei:" .. imei, "");

    if( not result or not string.equal(headers["response_code"], "200") ) then
        logger.log("firmware", 30, "Callout for version failed. Result was: ", result, " and response code: ", headers["response_code"])
    else
        logger.log("firmware", 10, "Response is ", response)

        version = tonumber(response)
        if( not version and response ~= "unknown") then
            logger.log("firmware", 30, "Invalid response. Expecting version number. Got: ", response)
        end

        if( result and version and version > 0 ) then
            if( string.equal(current_version, response) ) then
                logger.log("firmware", 10, "The running version and new versions are the same: ", current_version)
            else
                logger.log("firmware", 10, "Need to update. Running version is: ", tostring(current_version), " and new version is: ", response)
                if( is_version_quarantined(response) ) then
                    logger.log("firmware", 30, "Version ", response, " is already quarantined, not downloading")
                else
                    logger.log("firmware", 10, "Calling get_firmware")
                    local get_firmware_result = get_firmware(imei, response)
                    collectgarbage()
                    if( not get_firmware_result ) then
                        logger.log("firmware", 30, "Firmware retrieval failed. Not restarting.")
                    else
                        logger.log("firmware", 10, "New firmware retrieval was successful. Restarting script.")
                        thread.sleep(5000)
                        os.restartscript()
                        thread.sleep(60000)
                        logger.log("firmware", 30, "Script restart failed. Restarting device")
                        at.reset()
                        thread.sleep(3600000)
                        logger.log("firmware", 30, "ERROR: Device restart failed.")
                    end
                end
            end
        end
    end
    collectgarbage();
end
_M.check_firmware_and_maybe_update = check_firmware_and_maybe_update


local check_firmware_and_maybe_reset = function(imei, current_version)

    local result, headers, response = http_lib.http_connect_send_close(NET_CLIENT_ID_FIRMWARE, config.get_config_value("FIRMWARE_HOST"), 65535, "/get_firmware_version?ident=imei:" .. imei, "");

    if( not result or not string.equal(headers["response_code"], "200") ) then
        logger.log("firmware", 30, "Callout for version failed. Result was: ", result, " and response code: ", headers["response_code"])
    else
        logger.log("firmware", 10, "Response is ", response)

        version = tonumber(response)
        if( not version and response ~= "unknown") then
            logger.log("firmware", 30, "Invalid response. Expecting version number. Got: ", response)
        end

        if( result and version and version > 0 ) then
            if( string.equal(current_version, response) ) then
                logger.log("firmware", 10, "The running version and new versions are the same: ", current_version)
            else
                logger.log("firmware", 10, "Need to update. Running version is: ", tostring(current_version), " and new version is: ", response)
                if( is_version_quarantined(response) ) then
                    logger.log("firmware", 30, "Version ", response, " is already quarantined, not downloading")
                else
                    logger.log("firmware", 30, "New firmware ready to go. Restarting script to download.")
                    thread.sleep(5000)
                    os.restartscript()
                    thread.sleep(60000)
                    logger.log("firmware", 30, "Script restart failed. Restarting device")
                    at.reset()
                    thread.sleep(3600000)
                    logger.log("firmware", 30, "ERROR: Device restart failed.")
                end
            end
        end
    end
    collectgarbage();
end
_M.check_firmware_and_maybe_reset = check_firmware_and_maybe_reset

return _M
