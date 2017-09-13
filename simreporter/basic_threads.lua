local _M = {}

printdir(1)
print("In basic threads. Trying to load libraries.\r\n")

local tcp = require("tcp_client")
local encaps = require("encapsulation")
local at = require("at_commands")
local at_abs = require("at_abs")
local device = require("device")
local json = require("json")
local unzip = require("unzip")

local NMEA_EVENT = 35;

local DEBUG = true;
local recv_count = 0;
--local GPS_LOCK_TIME = 60000;
local NMEA_SLEEP_TIME = 30000;
local REPORT_INTERVAL = 3600000;
local NMEA_LOOP_COUNT = 5;
local MAIN_THREAD_SLEEP = 600000;
local MAX_MAIN_THREAD_LOOP_COUNT = 9999999;
local GPS_LOCK_CHECK_SLEEP_TIME = 20000;
local GPS_LOCK_CHECK_MAX_LOOP = 9999999;
local FIRMWARE_SLEEP_TIME = 45000;

-- Drop intervals when in debug mode
if( DEBUG ) then
    --GPS_LOCK_TIME = 10000;
    NMEA_SLEEP_TIME = 20000;
    REPORT_INTERVAL = 1800000;
    NMEA_LOOP_COUNT = 3;
    MAIN_THREAD_SLEEP = 600000;
    MAX_MAIN_THREAD_LOOP_COUNT = 9999999;
end;

local CELL_THREAD_SLEEP_TIME = REPORT_INTERVAL * 2;
local MIN_REPORT_TIME = (CELL_THREAD_SLEEP_TIME / 1000) - 5;
--- MIN_REPORT_TIME = MIN_REPORT_TIME * 1000;

local ati_string = at.get_device_info();
local last_cell_report = 0;
local imei = at_abs.get_imei()

local running_version;

function update_last_cell_report()
    thread.enter_cs(2);
    last_cell_report = os.clock();
    thread.leave_cs(2);
end;

function last_cell_report_has_expired()
    thread.enter_cs(2);
    local copy_of_last_cell_report = last_cell_report;
    thread.leave_cs(2);
    local now = os.clock();
    local time_since_last_report = now - copy_of_last_cell_report;
    print("Now is: ", tostring(now), " last reported time is: ", tostring(copy_of_last_cell_report), " difference is: ", tostring(time_since_last_report), "\r\n");
    print("Difference is: ", tostring(time_since_last_report), ", min report time is: ", tostring(MIN_REPORT_TIME), "\r\n");
    if copy_of_last_cell_report == 0 or time_since_last_report > MIN_REPORT_TIME then
        print("Returning true");
        return true;
    else
        print("Returning false");
        return false;
    end;
    
end;
    
    
function wait_until_lock(iterations)
    local gps_info = nil
    for i=1,iterations do
        local is_locked = at_abs.is_location_valid();
        if is_locked then
            print("GPS locked. Exiting wait.\r\n");
            return true
        end
        print("Not locked yet. Sleeping\r\n");
        thread.sleep(GPS_LOCK_CHECK_SLEEP_TIME);
    end
    print("GPS iterations exceeded. Exiting wait.\r\n");
    return false
end

function gps_tick()
    print("Starting gps tick function\r\n");
    local client_id = 1;
    while (true) do
        print("GPS data thread waking up\r\n");
        print("Turning gps on\r\n");
        gps.gpsstart(1);
        local gps_locked = wait_until_lock(GPS_LOCK_CHECK_MAX_LOOP);
        --thread.sleep(GPS_LOCK_TIME);
        print("Requesting nmea data\r\n");
        local open_net_result = tcp.open_network(client_id);
        print("Open network response is: ", open_net_result, "\r\n");
        for i=1,NMEA_LOOP_COUNT do

            local cell_table = device.get_device_info_table();
            local encapsulated_payload = encaps.encapsulate_data(ati_string, cell_table, i, NMEA_LOOP_COUNT);
            local result = tcp.http_open_send_close(client_id, "services.do.scattym.com", 65535, "/process_cell_update", encapsulated_payload);
            if result then
                update_last_cell_report();
            end;
            print("Result is ", tostring(result), "\r\n");

            local nmea_data = nmea.getinfo(63);
            if (nmea_data) then
                print("nmea_data, len=", string.len(nmea_data), "\r\n");
                local encapsulated_payload = encaps.encapsulate_nmea(ati_string, "nmea", nmea_data, i, NMEA_LOOP_COUNT);

                local result, response = tcp.http_open_send_close(client_id, "home.scattym.com", 65535, "/process_update", encapsulated_payload);
                print("Result is ", tostring(result), " and response is ", response, "\r\n");
            end;
            collectgarbage();
            thread.sleep(NMEA_SLEEP_TIME);
        end;
        tcp.close_network(client_id);
        print("Turning gps off\r\n");
        gps.gpsclose();
        print("Sleeping\r\n");
        print("GPS data thread sleeping for ", REPORT_INTERVAL / 1000, " seconds\r\n");
        collectgarbage();
        thread.sleep(REPORT_INTERVAL);
    end;
end;

function cell_tick()
    print("Starting cell data tick function\r\n");
    local client_id = 2;
    while (true) do
        print("Cell data thread waking up\r\n");
        if last_cell_report_has_expired() then
            tcp.open_network(client_id);
            for i=1,1 do
                local cell_table = device.get_device_info_table();
                local encapsulated_payload = encaps.encapsulate_data(ati_string, cell_table, i, NMEA_LOOP_COUNT);
                local result, response = tcp.http_open_send_close(client_id, "home.scattym.com", 65535, "/process_cell_update", encapsulated_payload);
                print("Result is ", tostring(result), " and response is ", response, "\r\n");
                if result then
                    update_last_cell_report();
                end;
                collectgarbage();
                thread.sleep(NMEA_SLEEP_TIME);
            end;
            tcp.close_network(client_id);
        else
            print("Cell data has already been reported at ", tostring(last_cell_report), "\r\n");
        end
        print("Cell data thread sleeping for ", CELL_THREAD_SLEEP_TIME / 1000, " seconds\r\n");
        collectgarbage();
        thread.sleep(CELL_THREAD_SLEEP_TIME);
    end;
end;

local function tohex(data)
    return (data:gsub(".", function (x)
        return ("%02x"):format(x:byte()) end)
    )
end

function get_firmware(version)
    local client_id = 4;
    local open_net_result = tcp.open_network(client_id);
    print("Open network response is: ", open_net_result, "\r\n");
    local result, response = tcp.http_open_send_close(client_id, "home.scattym.com", 65535, "/get_firmware?ident=imei:" .. imei, "");
    print("Response is ", response, "\r\n")
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
            print(firmware_json["file"]);
            print("\r\n")
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
                    unzip.unzip_file(zip_file_name, "c:/libs/" .. firmware_json["version"] .. "/")
                end
            end
        end
    end
    collectgarbage();
end

function get_firmware_version()
    print("Trying to retrieve firmware version\r\n");
    print("ati string: ", ati_string, " imei: ", imei, "\r\n")
    local client_id = 3;
    while (true) do
        local open_net_result = tcp.open_network(client_id);
        print("Open network response is: ", open_net_result, "\r\n");
        local result, response = tcp.http_open_send_close(client_id, "home.scattym.com", 65535, "/get_firmware_version?ident=imei:" .. imei, "");
        tcp.close_network(client_id);
        print("Response is ", response, "\r\n")

        if( result and response ) then
            if( not string.equal(running_version, response) ) then
                print("Need to update\r\n")
                if( is_version_quarantined(response) ) then
                    print("Version ", response, " is already quarantined, not downloading\r\n")
                else
                    print("Calling get_firmare\r\n")
                    get_firmware(response)
                end

            end
        end
        collectgarbage();
        thread.sleep(FIRMWARE_SLEEP_TIME);
    end
end

function start_threads(version)
    running_version = version;
    local gps_tick_thread = thread.create(gps_tick);
    local cell_tick_thread = thread.create(cell_tick);
    local firmware_check_thread = thread.create(get_firmware_version);
    print(tostring(gps_tick_thread), "\r\n");
    print(tostring(cell_tick_thread), "\r\n");
    print(tostring(firmware_check_thread), "\r\n");
    thread.sleep(1000);
    print("Starting threads\r\n");
    result = thread.run(gps_tick_thread);
    print("GPS start thread result is ", tostring(result), "\r\n");
    result = thread.run(cell_tick_thread);
    print("Cell data start thread result is ", tostring(result), "\r\n");
    result = thread.run(firmware_check_thread);
    print("Cell data start thread result is ", tostring(result), "\r\n");

    print("Threads are running\r\n");
    local counter = 0
    while (thread.running(gps_tick_thread) or thread.running(cell_tick_thread)) do
        print("Still running\r\n");
        thread.sleep(MAIN_THREAD_SLEEP);
        counter = counter+1;
        if( counter > MAX_MAIN_THREAD_LOOP_COUNT) then
            thread.stop(gps_tick_thread);
            gps.gpsclose();
            break;
        end;
        collectgarbage();
    end;
    print("all sub-threads ended\r\n");
end;

_M.start_threads = start_threads

return _M