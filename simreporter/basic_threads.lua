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
local logging = require("logging")

local logger = logging.create("basic_threads", 30)

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
    logger(10, "Now is: ", tostring(now), " last reported time is: ", tostring(copy_of_last_cell_report), " difference is: ", tostring(time_since_last_report));
    logger(10, "Difference is: ", tostring(time_since_last_report), ", min report time is: ", tostring(config.get_config_value("MIN_REPORT_TIME")));
    if copy_of_last_cell_report == 0 or time_since_last_report > config.get_config_value("MIN_REPORT_TIME") then
        logger(10, "Returning true");
        return true;
    else
        logger(10, "Returning false");
        return false;
    end;

end;


function wait_until_lock(iterations)
    for i=1,iterations do
        local is_locked = at_abs.is_location_valid();
        if is_locked then
            logger(10, "GPS locked. Exiting wait.");
            return true
        end
        logger(10, "Not locked yet. Sleeping");
        thread.sleep(config.get_config_value("GPS_LOCK_CHECK_SLEEP_TIME"));
    end
    logger(10, "GPS iterations exceeded. Exiting wait.");
    return false
end

function gps_tick()
    logger(10, "Starting gps tick function");
    local client_id = 1;
    while (true) do
        logger(10, "GPS data thread waking up");
        logger(10, "Turning gps on");
        gps.gpsstart(1);
        local gps_locked = wait_until_lock(config.get_config_value("GPS_LOCK_CHECK_MAX_LOOP"));
        --thread.sleep(GPS_LOCK_TIME);
        logger(10, "Requesting nmea data");
        local open_net_result = tcp.open_network(client_id);
        logger(10, "Open network response is: ", open_net_result);
        local max_loop_count = config.get_config_value("NMEA_LOOP_COUNT")
        local current_loop = 0
        while max_loop_count == 0 or current_loop <= max_loop_count do
            current_loop = current_loop + 1

            local cell_table = device.get_device_info_table();
            local encapsulated_payload = encaps.encapsulate_data(ati_string, cell_table, current_loop, config.get_config_value("NMEA_LOOP_COUNT"));
            local result, headers, payload = tcp.http_open_send_close(client_id, config.get_config_value("UPDATE_HOST"), config.get_config_value("UPDATE_PORT"), config.get_config_value("CELL_PATH"), encapsulated_payload, {}, true);
            if result and headers["response_code"] == "200" then
                update_last_cell_report();
            end;
            logger(10, "Result is ", tostring(result));

            local nmea_data = nmea.getinfo(63);
            if (nmea_data) then
                logger(10, "nmea_data, len=", string.len(nmea_data));
                local nmea_table = {}
                nmea_table["nmea"] = nmea_data
                local encapsulated_payload = encaps.encapsulate_data(ati_string, nmea_table, current_loop, config.get_config_value("NMEA_LOOP_COUNT"));

                local result, headers, response = tcp.http_open_send_close(client_id, config.get_config_value("UPDATE_HOST"), config.get_config_value("UPDATE_PORT"), config.get_config_value("GPS_PATH"), encapsulated_payload, {}, true);
                logger(10, "Result is ", tostring(result), " and response is ", response);
            end;
            collectgarbage();
            thread.sleep(config.get_config_value("NMEA_SLEEP_TIME"));
            max_loop_count = config.get_config_value("NMEA_LOOP_COUNT") -- Ensure we exit if config changes
        end;
        tcp.close_network(client_id);
        logger(10, "Turning gps off");
        gps.gpsclose();
        logger(10, "Sleeping");
        logger(10, "GPS data thread sleeping for ", config.get_config_value("REPORT_INTERVAL") / 1000, " seconds");
        collectgarbage();
        thread.sleep(config.get_config_value("REPORT_INTERVAL"));
    end;
end;

function cell_tick()
    logger(10, "Starting cell data tick function");
    local client_id = 2;
    while (true) do
        logger(10, "Cell data thread waking up");
        if last_cell_report_has_expired() then
            tcp.open_network(client_id);
            for i=1,1 do
                local cell_table = device.get_device_info_table();
                local encapsulated_payload = encaps.encapsulate_data(ati_string, cell_table, i, config.get_config_value("NMEA_LOOP_COUNT"));
                local result, headers, response = tcp.http_open_send_close(client_id, config.get_config_value("UPDATE_HOST"), config.get_config_value("UPDATE_PORT"), config.get_config_value("CELL_PATH"), encapsulated_payload, {}, true)
                logger(10, "Result is ", tostring(result), " and response is ", response);
                if result and headers["response_code"] == "200" then
                    update_last_cell_report();
                else
                    logger(30, "Update failed. Result is ", tostring(result), " and response is ", response);
                end;
                collectgarbage();
                thread.sleep(config.get_config_value("NMEA_SLEEP_TIME"));
            end;
            tcp.close_network(client_id);
        else
            logger(10, "Cell data has already been reported at ", tostring(last_cell_report));
        end
        logger(10, "Cell data thread sleeping for ", config.get_config_value("CELL_THREAD_SLEEP_TIME") / 1000, " seconds");
        collectgarbage();
        thread.sleep(config.get_config_value("CELL_THREAD_SLEEP_TIME"));
    end;
end;


function get_firmware_version()
    logger(10, "Trying to retrieve firmware version");
    logger(10, "imei: ", imei)
    local client_id = 3;
    while (true) do
        firmware.check_firmware_and_maybe_update(imei, running_version)
        collectgarbage()
        thread.sleep(config.get_config_value("FIRMWARE_SLEEP_TIME"));
    end
end

function get_config()
    logger(10, "Trying to retrieve config");
    logger(10, "imei: ", imei)
    logger(10, "imei: ", running_version)
    while (true) do
        local config_result = config.load_config_from_server(imei, running_version)
        logger(10, "Config load result was: ", config_result)
        logger(10, "mem used: ", getcurmem())
        config.dump_config()
        collectgarbage()
        thread.sleep(config.get_config_value("CONFIG_SLEEP_TIME"));
    end
end

local function tohex(data)
    return (data:gsub(".", function (x)
        return ("%02x"):format(x:byte()) end)
    )
end

local start_threads = function (version)
    running_version = version;
    logger(10, "Start of start_threads")
    -- logging.set_log_file("c:/log.txt")
    --logger(10, "Trying to load config first time\r\n")
    --local config_load_result = config.load_config_from_file()
    --logger(10, "Config load result is ", config_load_result, "\r\n")
    --logger(10, "Trying to save config to file")
    --local config_save_result = config.save_config_to_file()
    --logger(10, "Save config result is ", config_save_result)
    local gps_tick_thread = thread.create(gps_tick);
    local cell_tick_thread = thread.create(cell_tick);
    local firmware_check_thread = thread.create(get_firmware_version);
    local config_update_thread = thread.create(get_config);
    logger(10, "GPS tick thread: ", tostring(gps_tick_thread));
    logger(10, "cell_tick_thread: ", tostring(cell_tick_thread));
    logger(10, "Firmware check thread: ", tostring(firmware_check_thread));
    logger(10, "Config update thread: ", tostring(config_update_thread));
    thread.sleep(1000);
    logger(10, "Starting threads");
    result = thread.run(gps_tick_thread);
    logger(10, "GPS start thread result is ", tostring(result));
    result = thread.run(cell_tick_thread);
    logger(10, "Cell data start thread result is ", tostring(result));
    result = thread.run(firmware_check_thread);
    logger(10, "Firmware check start thread result is ", tostring(result));
    result = thread.run(config_update_thread);
    logger(10, "Config update start thread result is ", tostring(result));

    logger(10, "Threads are running");
    local counter = 0
    while thread.running(gps_tick_thread) and thread.running(cell_tick_thread) and thread.running(firmware_check_thread) and thread.running(config_update_thread) do
    --while thread.running(config_update_thread) do
        logger(10, "All threads still running");
        logger(10, "Peak memory used: ", getpeakmem());
        counter = counter+1;
        local main_thread_loop_count = config.get_config_value("MAX_MAIN_THREAD_LOOP_COUNT")
        if( main_thread_loop_count > 0 and counter > main_thread_loop_count) then
            thread.stop(gps_tick_thread);
            thread.stop(cell_tick_thread);
            thread.stop(firmware_check_thread);
            thread.stop(config_update_thread);
            gps.gpsclose();
            break;
        end;


        --[[local hosts = {6, 7, 16, 17 }
        --local hosts = {6, 7}
        for _,i in ipairs(hosts) do
        --for i=1,127 do
            for j=1,32 do
                local data = i2c.read_i2c_dev(i, j, 4)
                local hex = ""
                if data ~= false then
                    hex = string.format("%x", data)
                end
                logger(30, "", i, ":", data, ":", hex)
                thread.sleep(200)
            end
        end]]--

        collectgarbage();
        logger(30, "Main thread sleeping")
        thread.sleep(config.get_config_value("MAIN_THREAD_SLEEP"));
    end;
    logger(30, "One of the threads is not running or reached max loop count.");
    logger(30, "GPS tick thread running: ", thread.running(gps_tick_thread));
    logger(30, "cell_tick_thread running: ", thread.running(cell_tick_thread));
    logger(30, "Firmware check thread running: ", thread.running(firmware_check_thread));
    logger(30, "Config update thread running: ", thread.running(config_update_thread));
    logger(30, "Loop counter: ", counter);
    thread.sleep(2000)
    at.reset()
end;

_M.start_threads = start_threads

return _M