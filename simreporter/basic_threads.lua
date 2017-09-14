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
local config = require("config")
local firmware = require("firmware")

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
    print("Difference is: ", tostring(time_since_last_report), ", min report time is: ", tostring(config.get_config_value("MIN_REPORT_TIME")), "\r\n");
    if copy_of_last_cell_report == 0 or time_since_last_report > config.get_config_value("MIN_REPORT_TIME") then
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
        thread.sleep(config.get_config_value("GPS_LOCK_CHECK_SLEEP_TIME"));
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
        local gps_locked = wait_until_lock(config.get_config_value("GPS_LOCK_CHECK_MAX_LOOP"));
        --thread.sleep(GPS_LOCK_TIME);
        print("Requesting nmea data\r\n");
        local open_net_result = tcp.open_network(client_id);
        print("Open network response is: ", open_net_result, "\r\n");
        for i=1,config.get_config_value("NMEA_LOOP_COUNT") do

            local cell_table = device.get_device_info_table();
            local encapsulated_payload = encaps.encapsulate_data(ati_string, cell_table, i, NMEA_LOOP_COUNT);
            local result, headers, payload = tcp.http_open_send_close(client_id, "services.do.scattym.com", 65535, "/process_cell_update", encapsulated_payload);
            if result and headers["response_code"] == "200" then
                update_last_cell_report();
            end;
            print("Result is ", tostring(result), "\r\n");

            local nmea_data = nmea.getinfo(63);
            if (nmea_data) then
                print("nmea_data, len=", string.len(nmea_data), "\r\n");
                local encapsulated_payload = encaps.encapsulate_nmea(ati_string, "nmea", nmea_data, i, NMEA_LOOP_COUNT);

                local result, headers, response = tcp.http_open_send_close(client_id, "home.scattym.com", 65535, "/process_update", encapsulated_payload);
                print("Result is ", tostring(result), " and response is ", response, "\r\n");
            end;
            collectgarbage();
            thread.sleep(config.get_config_value("NMEA_SLEEP_TIME"));
        end;
        tcp.close_network(client_id);
        print("Turning gps off\r\n");
        gps.gpsclose();
        print("Sleeping\r\n");
        print("GPS data thread sleeping for ", config.get_config_value("REPORT_INTERVAL") / 1000, " seconds\r\n");
        collectgarbage();
        thread.sleep(config.get_config_value("REPORT_INTERVAL"));
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
                local encapsulated_payload = encaps.encapsulate_data(ati_string, cell_table, i, config.get_config_value("NMEA_LOOP_COUNT"));
                local result, headers, response = tcp.http_open_send_close(client_id, "home.scattym.com", 65535, "/process_cell_update", encapsulated_payload);
                print("Result is ", tostring(result), " and response is ", response, "\r\n");
                if result and headers["response_code"] == "200" then
                    update_last_cell_report();
                end;
                collectgarbage();
                thread.sleep(config.get_config_value("NMEA_SLEEP_TIME"));
            end;
            tcp.close_network(client_id);
        else
            print("Cell data has already been reported at ", tostring(last_cell_report), "\r\n");
        end
        print("Cell data thread sleeping for ", config.get_config_value("CELL_THREAD_SLEEP_TIME") / 1000, " seconds\r\n");
        collectgarbage();
        thread.sleep(config.get_config_value("CELL_THREAD_SLEEP_TIME"));
    end;
end;


function get_firmware_version()
    print("Trying to retrieve firmware version\r\n");
    print("imei: ", imei, "\r\n")
    local client_id = 3;
    while (true) do
        firmware.check_firmware_and_maybe_update(imei, running_version)
        thread.sleep(config.get_config_value("FIRMWARE_SLEEP_TIME"));
    end
end

function start_threads(version)
    running_version = version;

    print("Trying to load config first time\r\n")
    local config_load_result = config.load_config_from_file()
    print("Config load result is ", config_load_result, "\r\n")

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
    print("Firmware check start thread result is ", tostring(result), "\r\n");

    print("Threads are running\r\n");
    local counter = 0
    while (thread.running(gps_tick_thread) or thread.running(cell_tick_thread)) do
        print("Still running\r\n");
        thread.sleep(config.get_config_value("MAIN_THREAD_SLEEP"));
        counter = counter+1;
        if( config.get_config_value("MAX_MAIN_THREAD_LOOP_COUNT") > 0 and counter > config.get_config_value("MAX_MAIN_THREAD_LOOP_COUNT")) then
            thread.stop(gps_tick_thread);
            thread.stop(cell_tick_thread);
            thread.stop(firmware_check_thread);
            gps.gpsclose();
            break;
        end;
        collectgarbage();
    end;
    print("all sub-threads ended\r\n");
end;

_M.start_threads = start_threads

return _M