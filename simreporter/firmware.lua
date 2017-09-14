--
-- Created by IntelliJ IDEA.
-- User: matt
-- Date: 12/9/17
-- Time: 5:21 PM
-- To change this template use File | Settings | File Templates.
--

local _M = {}

local tcp = require("tcp_client")
local unzip = require("unzip")
local at = require("at_commands")
local json = require("json")

local client_id = 3

local function tohex(data)
    return (data:gsub(".", function (x)
        return ("%02x"):format(x:byte()) end)
    )
end

function get_firmware(imei, version)
    local fn_result = false
    local open_net_result = tcp.open_network(client_id);
    print("Open network response is: ", open_net_result, "\r\n");
    local result, headers, response = tcp.http_open_send_close(client_id, "home.scattym.com", 65535, "/get_firmware?ident=imei:" .. imei, "");
    if( not result or not string.equal(headers["response_code"], "200") ) then
        print("Callout for firmware failed. Result was: ", result, " and response code: ", headers["response_code"], "\r\n")
    else
        print("Response length is ", #response, "\r\n")
        local firmware_json = json.decode(response);
        tcp.close_network(client_id);
        print("\r\n")
        print(firmware_json);
        print("\r\n")
        if( is_version_quarantined(firmware_json["version"]) ) then
            print("Version ", firmware_json["version"], " is already quarantined, not expanding\r\n")
        else
            if( firmware_json["version"] and firmware_json["file"] and firmware_json["checksum"] ) then
                print(firmware_json["version"]);
                print("\r\n")
                print("File length: ", tostring(#firmware_json["file"]), "\r\n");
                print("Advertised checksum: ", tostring(firmware_json["checksum"]), "\r\n")
                raw_data = base64.decode(firmware_json["file"])
                hash = sha256.init()
                hash:update(raw_data)
                checksum = hash:final()
                checksum_hex = tohex(checksum)
                if( not string.equal(checksum_hex, firmware_json["checksum"]) ) then
                    print("Checksums do not match. Calculated checksum is: ", checksum_hex, " but should be: ", firmware_json["checksum"])
                else
                    if( raw_data ) then
                        local zip_file_name = "c:/" .. firmware_json["version"] .. ".zip"
                        file = io.open(zip_file_name,"w") assert(file)
                        file:write(raw_data, "\n")
                        file:close()
                        unzip_result = unzip.unzip_file(zip_file_name, "c:/libs/" .. firmware_json["version"] .. "/")
                        fn_result = unzip_result
                        print("Result of unzip is: ", unzip_result, "\r\n")
                        os.delfile(zip_file_name)
                        collectgarbage()
                    end
                end
            else
                print("One of the fields is missing. version: ", tostring(firmware_json["version"]), " file: ", tostring(#firmware_json["file"]), " checksum: ", tostring(firmware_json["checksum"]) )
            end
        end
    end
    collectgarbage();
    return fn_result
end

local check_firmware_and_maybe_update = function(imei, current_version)
    local open_net_result = tcp.open_network(client_id);
    print("Open network response is: ", open_net_result, "\r\n");
    local result, headers, response = tcp.http_open_send_close(client_id, "home.scattym.com", 65535, "/get_firmware_version?ident=imei:" .. imei, "");
    tcp.close_network(client_id);
    if( not result or not string.equal(headers["response_code"], "200") ) then
        print("Callout for version failed. Result was: ", result, " and response code: ", headers["response_code"], "\r\n")
    else
        print("Response is ", response, "\r\n")

        version = tonumber(response)
        if( not version ) then
            print("Invalid response. Expecting version number. Got: ", response, "\r\n")
        end

        if( result and version and version > 0 ) then
            if( string.equal(current_version, response) ) then
                print("The running version and new versions are the same: ", current_version, "\r\n")
            else
                print("Need to update. Running version is: ", tostring(current_version), " and new version is: ", response, "\r\n")
                if( is_version_quarantined(response) ) then
                    print("Version ", response, " is already quarantined, not downloading\r\n")
                else
                    print("Calling get_firmware\r\n")
                    local get_firmware_result = get_firmware(imei, response)
                    if( not get_firmware_result ) then
                        print("Firmware retrieval failed. Not restarting.\r\n")
                    else
                        print("New firmware retrieval was successful. Restarting script.\r\n")
                        thread.sleep(5000)
                        os.restartscript()
                        thread.sleep(60000)
                        print("Script restart failed. Restarting device\r\n")
                        at.reset()
                        thread.sleep(3600000)
                        print("ERROR: Device restart failed.\r\n")
                    end
                end
            end
        end
    end
    collectgarbage();
end

_M.check_firmware_and_maybe_update = check_firmware_and_maybe_update

return _M



