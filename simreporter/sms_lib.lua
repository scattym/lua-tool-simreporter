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
    local line_array = split(message:gsub("\r", ""), "\n")
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
    print("sms.send=", suc, ",", msg_ref_or_err_cause, "\r\n");
end


local wait_for_sms_thread = function(imei)
    -- at.set_cmgf("1")

    sms.set_cmgf(1);
    thread.setevtowner(SMS_EVENT_ID, SMS_EVENT_ID)
    local sms_ready = false
    while not sms_ready do
        sms_ready = sms.ready();
        print("sms.ready() = ", sms_ready, "\r\n");
        if (not sms_ready) then
          print("SMS not ready now\r\n");
        end;
        print("Sleeping")
        thread.sleep(10000)
    end

    print("Setting to get +CMTI/+CSDI\r\n");
    sms.set_cnmi(2,1)

    print("Wait +CMTI or +CDSI now...\r\n");
    while (true) do
        local evt, evt_p1, evt_p2, evt_p3, evt_clock = thread.waitevt(150000);
        if (evt ~= -1) then
            print("waited event, ", evt, ", ", evt_p1, ", ", evt_p2, ", ", evt_p2, ", ", evt_clock, "\r\n");
        end;
        if (evt and evt == SMS_EVENT_ID) then
            local rpt_type = evt_p1;
            local storage = evt_p2;
            local index = evt_p3;
            if (rpt_type == SMS_EVT_P1_CMTI) then
                print("Got CMTI:", ", storage=", storage, ", index=", index, "\r\n");
            elseif (rpt_type == SMS_EVT_P1_CDSI) then
                print("Got CDSI:", ", storage=", storage, ", index=", index, "\r\n");
            end;
            local rst, sms_content = sms.read(index);--just read, without modify the tag from "UNREAD" to "READ"
            print("sms.read[", msg_index, "]=", rst, "\r\n");
            if (not sms_content) then
                print("sms_content is nil\r\n");
            else
                print("TEXT sms_content=\r\n", sms_content, "\r\n");
                local message = parse_sms_message(sms_content)
                sms.delete(index)
                if message then
                    logger(0, "Parsed message from phone number: ", message["phone"], " at ", message["date"])
                    logger(0, "Message is ", message["message"])
                    if message["message"]:gmatch("GPSPLEASE") then
                        local gps_info = at_abs.get_location()
                        -- "lat", "north_south", "long", "east_west", "date", "time", "altitude", "speed", "course"
                        if gps_info then
                            local response = imei .. ":lat" .. tostring(gps_info["lat"]) .. tostring(gps_info["north_south"]) .. ":long" .. tostring(gps_info["long"]) .. tostring(gps_info["east_west"])
                            send_message_to_number(response, message["phone"])
                        end
                    end
                    if message["message"]:gmatch("RESETPLEASE") then
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