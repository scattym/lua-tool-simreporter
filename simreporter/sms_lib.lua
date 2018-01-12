_M = {}

local at = require("at_commands")
local config = require("config")
local util = require("util")
local logging = require("logging")
local at_abs = require("at_abs")
local logger = logging.create("sms_lib", 30)

local SMS_EVENT_ID = 26

local SMS_EVT_P1_CMTI = 0
local SMS_EVT_P1_CDSI = 1

local SMS_EVT_P2_ME = 0
local SMS_EVT_P2_SM = 1

local CSCS_IRA=0
local CSCS_GSM=1
local CSCS_UCS2=2


-- "REC UNREAD","+61402144176","","17/11/30,20:09:55+44",0,0,0
-- Test me
local parse_sms_header = function(line)
    local header_table = util.split(line, ",")
    if #header_table == 8 then
        local return_table = {}
        return_table["status"] = header_table[1]:gsub('"', '')
        return_table["phone"] = header_table[2]:gsub('"', '')
        return_table["date"] = header_table[4]:gsub('"', '') .. " " .. header_table[5]:gsub('"', '')
        return return_table
    end
    return nil
end

local parse_sms_message = function(message)
    local return_table = {}
    local line_array = util.split(message:gsub("\r", ""), "\n")
    if #line_array >= 1 then
        return_table = parse_sms_header(line_array[1])
        if not return_table then
            return nil
        end
        return_table["message"] = ""
    end
    if #line_array >= 2 then
        for i=2,#line_array do
            return_table["message"] = return_table["message"] .. " " .. line_array[i]
        end
    end
    return return_table
end

local send_message_to_number = function(message, number)
    os.set_cscs(CSCS_IRA);
    sms.set_cmgf(1);
    sms.set_csmp(17, 14, 0, 0);
    sms.set_cmgf(1);
    local suc, msg_ref_or_err_cause = sms.send(number, message);--send single sms, default is "UNSENT"
    logger(30, "sms.send=", suc, ",", msg_ref_or_err_cause);
end


local wait_for_sms_thread = function(imei)
    -- at.set_cmgf("1")

    sms.set_cmgf(1);
    thread.setevtowner(SMS_EVENT_ID, SMS_EVENT_ID)
    local sms_ready = false
    while not sms_ready do
        sms_ready = sms.ready();
        logger(30, "sms.ready() = ", sms_ready);
        if (not sms_ready) then
          logger(30, "SMS not ready now");
        end;
        logger(0, "Sleeping")
        thread.sleep(10000)
    end

    -- print("Setting to get +CMTI/+CSDI\r\n");
    sms.set_cnmi(2, 1, 2, 2, 0)

    -- print("Wait +CMTI or +CDSI now...\r\n");
    while (true) do
        local evt, evt_p1, evt_p2, evt_p3, evt_clock = thread.waitevt(150000);
        if (evt ~= -1) then
            logger(0, "waited event, ", evt, ", ", evt_p1, ", ", evt_p2, ", ", evt_p2, ", ", evt_clock);
        end;
        if (evt and evt == SMS_EVENT_ID) then
            local rpt_type = evt_p1;
            local storage = evt_p2;
            local index = evt_p3;
            if (rpt_type == SMS_EVT_P1_CMTI) then
                logger(30, "Got CMTI:", ", storage=", storage, ", index=", index);
            elseif (rpt_type == SMS_EVT_P1_CDSI) then
                logger(30, "Got CDSI:", ", storage=", storage, ", index=", index);
            end;
            local rst, sms_content = sms.read(index);--just read, without modify the tag from "UNREAD" to "READ"
            logger(30, "sms.read[", msg_index, "]=", rst);
            if (not sms_content) then
                logger(30, "sms_content is nil");
            else
                logger(30, "TEXT sms_content=", sms_content);
                local message = parse_sms_message(sms_content)
                sms.delete(index)
                if message then
                    logger(0, "Parsed message from phone number: ", message["phone"], " at ", message["date"])
                    logger(0, "Message is ", message["message"])
                    if message["message"]:match("GPSPLEASE") then
                        local send_content = imei
                        local gps_info = at_abs.get_location()
                        -- "lat", "north_south", "long", "east_west", "date", "time", "altitude", "speed", "course"
                        if gps_info and gps_info["lat"] and gps_info["lat"] ~= "" then
                            send_content = send_content .. ":lat" .. tostring(gps_info["lat"]) .. tostring(gps_info["north_south"]) .. ":long" .. tostring(gps_info["long"]) .. tostring(gps_info["east_west"])
                            -- local response = imei .. ":lat" .. tostring(gps_info["lat"]) .. tostring(gps_info["north_south"]) .. ":long" .. tostring(gps_info["long"]) .. tostring(gps_info["east_west"])
                            -- 
                        else
                            send_content = send_content .. " no current gps signal"
                        end
                        send_message_to_number(send_content, message["phone"])
                    end
                    if message["message"]:match("RESETPLEASE") then
                        at.reset()
                    end
                else
                    logger(30, "Failed to parse message with content: ", sms_content)
                end

            end;

        end;
    end;
end
_M.wait_for_sms_thread = wait_for_sms_thread

return _M