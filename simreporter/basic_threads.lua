local _M = {}

local encaps = require("encapsulation")
local at = require("at_commands")
local at_abs = require("at_abs")
local device = require("device")
local json = require("json")
local config = require("config")
local firmware = require("firmware")
local logging = require("logging")
local network_setup = require("network_setup")
local socket_lib = require("socket_thread")
local sms_lib = require("sms_lib")
local http_reporter = require("http_reporter")
local event_farmer = require("event_farmer")
local gpio_lib = require("gpio_lib")
local http_lib = require("http_lib")
local keygen = require("keygen")
local aes = require("aes")

local logger = logging.create("basic_threads", 30)

local ati_string = at.get_device_info();
local last_cell_report = 0;
local last_gps_report = 0;
local imei = at_abs.get_imei()
local EXTRA_INFO = {}
local running_version;

local NET_CLIENT_ID_GPS = 1
local NET_CLIENT_ID_CARD = 5
local NET_CLIENT_ID_SOCKET = 8
local NET_CLIENT_ID_MESSAGE_QUEUE = 9

local CRITICAL_SECTION_CELL = 2
local CRITICAL_SECTION_CHARGING_CHECK = 6
local CRITICAL_SECTION_GPS = 7
local CRITICAL_SECTION_REPORTER = 8

local WAIT_EVENT_SOCKET_SEND = 40
local WAIT_EVENT_MESSAGE_QUEUE = 39

local card_reader_send_thread

local function tohex(data)
    return (data:gsub(".", function (x)
        return ("%02x"):format(x:byte()) end)
    )
end

local function update_last_gps_report()
    thread.enter_cs(CRITICAL_SECTION_GPS);
    last_gps_report = os.clock();
    thread.leave_cs(CRITICAL_SECTION_GPS);
end;

local function update_last_cell_report()
    thread.enter_cs(CRITICAL_SECTION_CELL);
    last_cell_report = os.clock();
    thread.leave_cs(CRITICAL_SECTION_CELL);
end;

local function last_gps_report_has_expired()
    thread.enter_cs(CRITICAL_SECTION_GPS);
    local copy_of_last_gps_report = last_gps_report;
    thread.leave_cs(CRITICAL_SECTION_GPS);
    local now = os.clock();
    local time_since_last_report = now - copy_of_last_gps_report;
    logger(10, "Now is: ", tostring(now), " last reported time is: ", tostring(copy_of_last_gps_report), " difference is: ", tostring(time_since_last_report));
    logger(10, "Difference is: ", tostring(time_since_last_report), ", min report time is: ", tostring(config.get_config_value("MIN_GPS_REPORT_TIME")));
    if copy_of_last_gps_report == 0 or time_since_last_report > config.get_config_value("MIN_GPS_REPORT_TIME") then
        logger(10, "Returning true");
        return true;
    else
        logger(10, "Returning false");
        return false;
    end;

end;

local function last_cell_report_has_expired()
    thread.enter_cs(CRITICAL_SECTION_CELL);
    local copy_of_last_cell_report = last_cell_report;
    thread.leave_cs(CRITICAL_SECTION_CELL);
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

local function should_reboot()
    if config.get_config_value("SHOULD_REBOOT") == "true" then
        return true
    end
    thread.enter_cs(CRITICAL_SECTION_CELL)
    local copy_of_last_cell_report = last_cell_report
    thread.leave_cs(CRITICAL_SECTION_CELL)
    local now = os.clock();
    local time_since_last_report = now - copy_of_last_cell_report
    logger(10, "should_reboot(): Now is: ", tostring(now), " last reported time is: ", tostring(copy_of_last_cell_report), " difference is: ", tostring(time_since_last_report));
    logger(10, "should_reboot(): Difference is: ", tostring(time_since_last_report), ", min report time is: ", tostring(config.get_config_value("INACTIVITY_REBOOT_TIME")));
    if time_since_last_report > config.get_config_value("INACTIVITY_REBOOT_TIME") then
        logger(10, "should_reboot(): Returning true");
        return true;
    else
        logger(10, "should_reboot(): Returning false");
        return false;
    end;

end;


local function wait_until_lock(iterations)
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

local IS_CHARGING = true
local function set_charging(value)
    thread.enter_cs(CRITICAL_SECTION_CHARGING_CHECK)
    IS_CHARGING = value
    thread.leave_cs(CRITICAL_SECTION_CHARGING_CHECK)
end

function is_charging()
    if config.get_config_value("CHECK_FOR_CHARGING") == "false" then
        return true
    end
    local return_val
    thread.enter_cs(CRITICAL_SECTION_CHARGING_CHECK)
    return_val = IS_CHARGING
    thread.leave_cs(CRITICAL_SECTION_CHARGING_CHECK)
    return return_val
end

local function charging_check()
    local down_count = 0
    local up_count = 0
    local prev_level = 0
    while true do
        local battery_table = at_abs.get_battery_table()
        local battery_percent = tonumber(battery_table["battery_percent"])
        if not battery_percent then
            battery_percent = 0
        end
        if battery_percent > config.get_config_value("MAX_BAT_PERCENT_CHARGE_CHECK") then
            logger(10, "Battery above high water marker. Setting charging true. Battery level: ", battery_percent)
            set_charging(true)
            up_count = 0
            down_count = 0
        else
            local battery_voltage_str = battery_table["battery_voltage"]

            if battery_voltage_str then

                local battery_voltage = tonumber((battery_voltage_str:gsub("V", "")))

                if battery_voltage < prev_level then
                    down_count = down_count + 1
                    up_count = 0
                    if down_count >= config.get_config_value("MAX_VOLT_DROP_COUNT") then
                        logger(30, "Max volt drop count reached. Set charging false.")
                        set_charging(false)
                        up_count = 0
                        down_count = 0
                    end
                end
                if battery_voltage > prev_level then
                    up_count = up_count + 1
                    if up_count >= config.get_config_value("MAX_VOLT_GAIN_COUNT") then
                        logger(30, "Battery is charging.")
                        set_charging(true)
                        up_count = 0
                        down_count = 0
                    end
                end
                prev_level = battery_voltage
            end
        end
        thread.sleep(config.get_config_value("CHARGING_CHECK_THREAD_SLEEP_TIME"))
    end

end

local function gps_tick()
    logger(10, "Starting gps tick function");
    local failure_count = 0

    local client_id = 1;
    while (true) do
        logger(10, "GPS data thread waking up");
        local battery_table = at_abs.get_battery_table()
        local battery_percent = tonumber(battery_table["battery_percent"])
        if not battery_percent then
            logger(30, "No battery level returned. Setting to 0.")
            battery_percent = 0
        end
        if battery_percent < config.get_config_value("MIN_BAT_PERCENT_FOR_GPS") then
            logger(30, "Battery level too low. Not turning on GPS.")
        else
            if is_charging() or last_gps_report_has_expired() then
                logger(10, "Turning gps on")
                gps.gpsstart(1);
                local gps_locked = wait_until_lock(config.get_config_value("GPS_LOCK_CHECK_MAX_LOOP"));

                logger(10, "Requesting nmea data");

                local max_loop_count = config.get_config_value("NMEA_LOOP_COUNT")
                local current_loop = 0
                while (max_loop_count == 0 or current_loop <= max_loop_count) and (is_charging() or last_gps_report_has_expired()) do
                    current_loop = current_loop + 1

                    if config.get_config_value("REPORT_DEVICE_INFO_WITH_GPS") == "true" then
                        local cell_table = device.get_device_info_table();
                        cell_table["extra_info"] = EXTRA_INFO
                        cell_table["running_version"] = tostring(running_version)

                        local encapsulated_payload = encaps.encapsulate_data(ati_string, cell_table, current_loop, config.get_config_value("NMEA_LOOP_COUNT"));
                        http_reporter.add_message(
                            nil,
                            encapsulated_payload,
                            {},
                            config.get_config_value("UPDATE_HOST"),
                            config.get_config_value("UPDATE_PORT"),
                            config.get_config_value("CELL_PATH"),
                            true
                        )
                        update_last_cell_report();
                    end

                    local nmea_data = nmea.getinfo(511);
                    if (nmea_data) then
                        logger(10, "nmea_data, len=", string.len(nmea_data));
                        local nmea_table = {}
                        nmea_table["nmea"] = nmea_data
                        if config.get_config_value("REPORT_CELL_WITH_GPS") == "true" then
                            nmea_table["cell_info"] = at.get_cell_info()
                        end
                        local encapsulated_payload = encaps.encapsulate_data(ati_string, nmea_table, current_loop, config.get_config_value("NMEA_LOOP_COUNT"));
                        http_reporter.add_message(
                            nil,
                            encapsulated_payload,
                            {},
                            config.get_config_value("UPDATE_HOST"),
                            config.get_config_value("UPDATE_PORT"),
                            config.get_config_value("GPS_PATH"),
                            true
                        )
                        -- socket_lib.send_data(NET_CLIENT_ID_SOCKET, encapsulated_payload)
                    end;
                    collectgarbage();
                    update_last_gps_report() -- Update regardless of result as we want one try only
                    thread.sleep(config.get_config_value("NMEA_SLEEP_TIME"));
                    max_loop_count = config.get_config_value("NMEA_LOOP_COUNT") -- Ensure we exit if config changes
                end;
                -- tcp.close_network(client_id);
                logger(10, "Turning gps off");
                gps.gpsclose();
            else
                logger(10, "Not charging and min gps report time has not expired. Not turning on GPS.");
            end
        end
        logger(10, "Sleeping");
        logger(10, "GPS data thread sleeping for ", config.get_config_value("REPORT_INTERVAL") / 1000, " seconds");
        collectgarbage();
        thread.sleep(config.get_config_value("GPS_THREAD_SLEEP_TIME"));
    end;
end;

local function cell_tick()
    logger(10, "Starting cell data tick function");

    local key_data = true
    local failure_count = 0

    while (true) do
        logger(10, "Cell data thread waking up");
        if last_cell_report_has_expired() then
            for i=1,1 do
                local cell_table = device.get_device_info_table()
                cell_table["extra_info"] = EXTRA_INFO
                cell_table["running_version"] = tostring(running_version)
                local encapsulated_payload = encaps.encapsulate_data(ati_string, cell_table, 1, 1)
                -- message, headers, host, port, path, encrypt
                http_reporter.add_message(
                    nil,
                    encapsulated_payload,
                    {},
                    config.get_config_value("UPDATE_HOST"),
                    config.get_config_value("UPDATE_PORT"),
                    config.get_config_value("CELL_PATH"),
                    key_data
                )
            end
        else
            logger(10, "Cell data has already been reported at ", tostring(last_cell_report));
        end
        logger(10, "Cell data thread sleeping for ", config.get_config_value("CELL_THREAD_SLEEP_TIME") / 1000, " seconds");
        collectgarbage();
        thread.sleep(config.get_config_value("CELL_THREAD_SLEEP_TIME"));
    end;
end;


local function get_firmware_version()
    logger(10, "Trying to retrieve firmware version");
    logger(10, "imei: ", imei)
    local client_id = 3;
    while (true) do
        if config.get_config_value("CHECK_FOR_FIRMWARE_IN_THREADS") == "true" then
            firmware.check_firmware_and_maybe_reset(imei, running_version)
            collectgarbage()
        end
        thread.sleep(config.get_config_value("FIRMWARE_SLEEP_TIME"));
    end
end

local function get_config()
    logger(10, "Trying to retrieve config");
    logger(10, "imei: ", imei)
    logger(10, "imei: ", running_version)

    while (true) do
        local config_result = config.load_config_from_server(imei, running_version)
        logger(10, "Config load result was: ", config_result)
        logger(10, "mem used: ", getcurmem())
        --config.dump_config()
        collectgarbage()
        thread.sleep(config.get_config_value("CONFIG_SLEEP_TIME"));
    end
end

local parse_json_command = function(json_str)
    local data = json.decode(json_str)
    for key, value in pairs(data) do
        EXTRA_INFO[key] = {}
        EXTRA_INFO[key]["clock"] = os.clock()
        EXTRA_INFO[key]["value"] = value
    end
end

-- AT+CARDR=test
local function handle_card_read_command(cmd_port, cmd_name, cmd_op, cmd_line, cmd_status)
    logger(30, "Got a card read command")
    logger(30, cmd_port)
    logger(30, cmd_name)
    logger(30, cmd_op)
    logger(30, cmd_line)
    logger(30, cmd_status)
    local command, value = cmd_line:match("([^=]+)=(.*)")
    logger(30, "Command: ", command, " value: ", value)
    -- add_message(value)
    local data = {}
    data["card_read"] = value
    local encapsulated_payload = encaps.encapsulate_data(ati_string, data, 0, 0)
    http_reporter.add_message(
        nil,
        encapsulated_payload,
        {},
        config.get_config_value("UPDATE_HOST"),
        config.get_config_value("UPDATE_PORT"),
        config.get_config_value("CARD_READ_PATH"),
        true
    )
end


local function handle_uart_data_cb(data)
    local base64_data = base64.encode(data)
    local command = "AT+CARDR=" .. base64_data
    handle_card_read_command("uart", "cardr", "op", command, "status")
end

local function testing_thread()
    at.register_command("+CARDR", handle_card_read_command, 1)
    while true do
        pcall(at.wait_at_command_thread, handle_uart_data_cb)
        logger(30, "Wait command function exited. Sleeping before restart")
        thread.sleep(10000)
    end
end

local function uart_read_thread_f()
    while true do
        pcall(at.wait_uart_data, handle_uart_data_cb)
        logger(30, "Uart read function exited. Sleeping before restart")
        thread.sleep(10000)
    end
end

local function socket_thread_f()
    while true do
        pcall(socket_lib.socket_thread, NET_CLIENT_ID_SOCKET, imei, running_version)
        logger(30, "Socket function exited. Sleeping before restart")
        thread.sleep(10000)
    end
end

local function start_sms_thread()

    while true do
        pcall(sms_lib.wait_for_sms_thread, imei)
        logger(30, "SMS function exited. Sleeping before restart")
        thread.sleep(10000)
    end
end

local function get_battery_percent()
    local battery_table = at_abs.get_battery_table()
    local battery_percent = tonumber(battery_table["battery_percent"])
    if not battery_percent then
        logger(30, "No battery level returned. Setting to 0.");
        battery_percent = 0
    end
    return battery_percent
end

local function device_setup()
    local response = at.enable_time_updates()
    network_setup.set_network_from_sms_operator();
end

local function gpio_handler(pin, state, clock)
    logger(30, "Pin: ", pin, " state: ", state, " clock: ", clock)
end

local THREAD_LIST = {}
local function start_thread(name, thread_func)
    local thread_ptr = thread.create(thread_func)
    logger(10, "Thread: ", name, " has id: ", thread_ptr)
    THREAD_LIST[name] = thread_ptr
    local result = thread.run(thread_ptr)
    logger(10, "Starting thread ", name, " result is ", tostring(result))
end

local function all_threads_running()
    local all_running = true
    for key, value in pairs(THREAD_LIST) do
        if thread.running(value) == false then
            logger(30, "Thread ", key, " with id ", value, " is no longer running")
            all_running = false
        end
    end
    return all_running
end


local start_threads = function (version)
    running_version = version;

    while get_battery_percent() < config.get_config_value("MIN_BAT_PERCENT_FOR_BOOT") do
        logger(30, "Battery level too low not starting threads.")
        vmsleep(30000)
    end

    http_lib.set_device_params(imei, running_version)

    device_setup()
    vmsleep(2000);
    local config_attempts = 0
    local config_loaded = false
    while not config_loaded and config_attempts < config.get_config_value("MAX_CONFIG_ON_BOOT_CALLOUTS") do
        config_attempts = config_attempts + 1
        config_loaded = config.load_config_from_server(imei, running_version)
        if not config_loaded then
            logger(30, "Callout for config failed. Sleeping for 3 seconds before retrying.")
            vmsleep(3000)
        end
    end
    if config_loaded == false then
        logger(30, "Attempt to load config on boot failed. Giving up and continuing")
    end

    if config.get_config_value("CHECK_FOR_FIRMWARE_ON_BOOT") == "true" then
        firmware.check_firmware_and_maybe_update(imei, running_version)
    end

    local session_key
    local enc_login_message
    if config.get_config_value("USE_SESSION_KEY") == "true" then
        logger(0, "Starting key gen")
        session_key, enc_login_message = keygen.create_and_encrypt_key(imei, 16)
        logger(0, "Done encrypting key")
    end

    local http_reporter_thread, running = http_reporter.start_thread(imei, running_version, session_key, enc_login_message)
    logger(10, "HTTP reporter thread start result is ", running)

    event_farmer.add_event_handler(0, gpio_lib.gpio_event_handler_cb)
    -- Set pin 42 to default high, level triggered, trigger on low and save
    gpio_lib.add_gpio_handler(42, 0, 0, 1, 1, gpio_handler)
    gpio_lib.add_gpio_handler(5, 0, 0, 1, 1, gpio_handler)

    logger(10, "Start of start_threads")
    start_thread("config_update", get_config)
    start_thread("gps_tick", gps_tick)
    start_thread("cell_tick", cell_tick)
    start_thread("firmware_check", get_firmware_version)
    start_thread("test_thread", testing_thread)
    start_thread("charging_check", charging_check)
    start_thread("sms_processor", start_sms_thread)
    start_thread("socket_thread", socket_thread_f)
    start_thread("uart_read_thread", uart_read_thread_f)

    start_thread("gpio_handler", gpio_lib.gpio_handler_thread_wrapper)
    start_thread("event_handler", event_farmer.event_handler_thread_wrapper)

    logger(10, "Threads are running");
    local counter = 0
    while thread.running(http_reporter_thread) and all_threads_running() do
    --while thread.running(config_update_thread) do
        logger(10, "All threads still running");
        logger(10, "Peak memory used: ", getpeakmem());
        counter = counter+1;
        local main_thread_loop_count = config.get_config_value("MAX_MAIN_THREAD_LOOP_COUNT")
        if( main_thread_loop_count > 0 and counter > main_thread_loop_count) then
            thread.stop(http_reporter_thread)
            gps.gpsclose()
            break
        end

        collectgarbage();
        if should_reboot() then
            logger(30, "Reached inactivity timer. Rebooting.")
            thread.sleep(10000)
            at.reset()
        end
        setevt(WAIT_EVENT_MESSAGE_QUEUE)
        logger(30, "Main thread sleeping. Max mem: ", tostring(getpeakmem()))
        thread.sleep(config.get_config_value("MAIN_THREAD_SLEEP"));
    end;
    logger(30, "One of the threads is not running or reached max loop count.");
    logger(30, "HTTP reporter thread running: ", thread.running(http_reporter_thread))

    logger(30, "Loop counter: ", counter);
    thread.sleep(2000)
    at.reset()
    return false
end;

_M.start_threads = start_threads

return _M
