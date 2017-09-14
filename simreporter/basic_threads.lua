local _M = {}

local tcp = require("tcp_client")
local encaps = require("encapsulation")
local at = require("at_commands")
local at_abs = require("at_abs")
local device = require("device")
local json = require("json")
local unzip = require("unzip")
local config = require("config")
local firmware = require("firmware")
local logger = require("logging")

logger.create_logger("basic_threads", 0)

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
    logger.log("basic_threads", 10, "Now is: ", tostring(now), " last reported time is: ", tostring(copy_of_last_cell_report), " difference is: ", tostring(time_since_last_report));
    logger.log("basic_threads", 10, "Difference is: ", tostring(time_since_last_report), ", min report time is: ", tostring(config.get_config_value("MIN_REPORT_TIME")));
    if copy_of_last_cell_report == 0 or time_since_last_report > config.get_config_value("MIN_REPORT_TIME") then
        logger.log("basic_threads", 10, "Returning true");
        return true;
    else
        logger.log("basic_threads", 10, "Returning false");
        return false;
    end;

end;


function wait_until_lock(iterations)
    local gps_info = nil
    for i=1,iterations do
        local is_locked = at_abs.is_location_valid();
        if is_locked then
            logger.log("basic_threads", 10, "GPS locked. Exiting wait.");
            return true
        end
        logger.log("basic_threads", 10, "Not locked yet. Sleeping");
        thread.sleep(config.get_config_value("GPS_LOCK_CHECK_SLEEP_TIME"));
    end
    logger.log("basic_threads", 10, "GPS iterations exceeded. Exiting wait.");
    return false
end

function gps_tick()
    logger.log("basic_threads", 10, "Starting gps tick function");
    local client_id = 1;
    while (true) do
        logger.log("basic_threads", 10, "GPS data thread waking up");
        logger.log("basic_threads", 10, "Turning gps on");
        gps.gpsstart(1);
        local gps_locked = wait_until_lock(config.get_config_value("GPS_LOCK_CHECK_MAX_LOOP"));
        --thread.sleep(GPS_LOCK_TIME);
        logger.log("basic_threads", 10, "Requesting nmea data");
        local open_net_result = tcp.open_network(client_id);
        logger.log("basic_threads", 10, "Open network response is: ", open_net_result);
        local max_loop_count = config.get_config_value("NMEA_LOOP_COUNT")
        local current_loop = 0
        while max_loop_count == 0 or current_loop <= max_loop_count do
            current_loop = current_loop + 1

            local cell_table = device.get_device_info_table();
            local encapsulated_payload = encaps.encapsulate_data(ati_string, cell_table, current_loop, NMEA_LOOP_COUNT);
            local result, headers, payload = tcp.http_open_send_close(client_id, "home.scattym.com", 65535, "/v2/process_update", encapsulated_payload);
            if result and headers["response_code"] == "200" then
                update_last_cell_report();
            end;
            logger.log("basic_threads", 10, "Result is ", tostring(result));

            local nmea_data = nmea.getinfo(63);
            if (nmea_data) then
                logger.log("basic_threads", 10, "nmea_data, len=", string.len(nmea_data));
                local nmea_table = {}
                nmea_table["nmea"] = nmea_data
                local encapsulated_payload = encaps.encapsulate_data(ati_string, nmea_table, current_loop, NMEA_LOOP_COUNT);

                local result, headers, response = tcp.http_open_send_close(client_id, "home.scattym.com", 65535, "/v2/process_cell_update", encapsulated_payload);
                logger.log("basic_threads", 10, "Result is ", tostring(result), " and response is ", response);
            end;
            collectgarbage();
            thread.sleep(config.get_config_value("NMEA_SLEEP_TIME"));
        end;
        tcp.close_network(client_id);
        logger.log("basic_threads", 10, "Turning gps off");
        gps.gpsclose();
        logger.log("basic_threads", 10, "Sleeping");
        logger.log("basic_threads", 10, "GPS data thread sleeping for ", config.get_config_value("REPORT_INTERVAL") / 1000, " seconds");
        collectgarbage();
        thread.sleep(config.get_config_value("REPORT_INTERVAL"));
    end;
end;

function cell_tick()
    logger.log("basic_threads", 10, "Starting cell data tick function");
    local client_id = 2;
    while (true) do
        logger.log("basic_threads", 10, "Cell data thread waking up");
        if last_cell_report_has_expired() then
            tcp.open_network(client_id);
            for i=1,1 do
                local cell_table = device.get_device_info_table();
                local encapsulated_payload = encaps.encapsulate_data(ati_string, cell_table, i, config.get_config_value("NMEA_LOOP_COUNT"));
                local result, headers, response = tcp.http_open_send_close(client_id, "home.scattym.com", 65535, "/v2/process_update", encapsulated_payload);
                logger.log("basic_threads", 10, "Result is ", tostring(result), " and response is ", response);
                if result and headers["response_code"] == "200" then
                    update_last_cell_report();
                end;
                collectgarbage();
                thread.sleep(config.get_config_value("NMEA_SLEEP_TIME"));
            end;
            tcp.close_network(client_id);
        else
            logger.log("basic_threads", 10, "Cell data has already been reported at ", tostring(last_cell_report));
        end
        logger.log("basic_threads", 10, "Cell data thread sleeping for ", config.get_config_value("CELL_THREAD_SLEEP_TIME") / 1000, " seconds\r\n");
        collectgarbage();
        thread.sleep(config.get_config_value("CELL_THREAD_SLEEP_TIME"));
    end;
end;


function get_firmware_version()
    logger.log("basic_threads", 10, "Trying to retrieve firmware version");
    logger.log("basic_threads", 10, "imei: ", imei)
    local client_id = 3;
    while (true) do
        firmware.check_firmware_and_maybe_update(imei, running_version)
        thread.sleep(config.get_config_value("FIRMWARE_SLEEP_TIME"));
    end
end

local start_threads = function (version)
    running_version = version;
    logger.log("basic_threads", 10, "Start of start_threads")
    --logger.log("basic_threads", 10, "Trying to load config first time\r\n")
    --local config_load_result = config.load_config_from_file()
    --logger.log("basic_threads", 10, "Config load result is ", config_load_result, "\r\n")
    logger.log("basic_threads", 10, "Trying to save config to file")
    local config_save_result = config.save_config_to_file()
    logger.log("basic_threads", 10, "Save config result is ", config_save_result)

    local gps_tick_thread = thread.create(gps_tick);
    local cell_tick_thread = thread.create(cell_tick);
    local firmware_check_thread = thread.create(get_firmware_version);
    logger.log("basic_threads", 10, tostring(gps_tick_thread));
    logger.log("basic_threads", 10, tostring(cell_tick_thread));
    logger.log("basic_threads", 10, tostring(firmware_check_thread));
    thread.sleep(1000);
    logger.log("basic_threads", 10, "Starting threads");
    result = thread.run(gps_tick_thread);
    logger.log("basic_threads", 10, "GPS start thread result is ", tostring(result));
    result = thread.run(cell_tick_thread);
    logger.log("basic_threads", 10, "Cell data start thread result is ", tostring(result));
    result = thread.run(firmware_check_thread);
    logger.log("basic_threads", 10, "Firmware check start thread result is ", tostring(result));

    logger.log("basic_threads", 10, "Threads are running");
    local counter = 0
    while (thread.running(gps_tick_thread) or thread.running(cell_tick_thread)) do
        logger.log("basic_threads", 10, "Still running");
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
    logger.log("basic_threads", 30, "All sub-threads ended. Resetting device");
    at.reset()
end;

_M.start_threads = start_threads

return _M