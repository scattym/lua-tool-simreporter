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
local keygen = require("keygen")
local rsa = require("rsa_lib")
local network_setup = require("network_setup")
local aes = require("aes")
local out_command = require("out_command")

local logger = logging.create("basic_threads", 30)

local ati_string = at.get_device_info();
local last_cell_report = 0;
local imei = at_abs.get_imei()
local key = ""
local enc_key = ""
local EXTRA_INFO = {}
local running_version;

local function tohex(data)
    return (data:gsub(".", function (x)
        return ("%02x"):format(x:byte()) end)
    )
end

local function update_last_cell_report()
    thread.enter_cs(2);
    last_cell_report = os.clock();
    thread.leave_cs(2);
end;

local function last_cell_report_has_expired()
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

local function gps_tick()
    logger(10, "Starting gps tick function");
    local client_id = 1;
    while (true) do
        logger(10, "GPS data thread waking up");
        logger(10, "Turning gps on");
        gps.gpsstart(1);
        local gps_locked = wait_until_lock(config.get_config_value("GPS_LOCK_CHECK_MAX_LOOP"));
        --thread.sleep(GPS_LOCK_TIME);
        logger(10, "Requesting nmea data");
        --local open_net_result = tcp.open_network(client_id);
        --logger(10, "Open network response is: ", open_net_result);
        local max_loop_count = config.get_config_value("NMEA_LOOP_COUNT")
        local current_loop = 0
        while max_loop_count == 0 or current_loop <= max_loop_count do
            current_loop = current_loop + 1

            local cell_table = device.get_device_info_table();
            cell_table["extra_info"] = EXTRA_INFO

            local encapsulated_payload = encaps.encapsulate_data(ati_string, cell_table, current_loop, config.get_config_value("NMEA_LOOP_COUNT"));
            local result, headers, payload = tcp.http_open_send_close(client_id, config.get_config_value("UPDATE_HOST"), config.get_config_value("UPDATE_PORT"), config.get_config_value("CELL_PATH"), encapsulated_payload, {}, true);
            if result and headers["response_code"] == "200" then
                update_last_cell_report();
            end;
            logger(10, "Result is ", tostring(result));

            local nmea_data = nmea.getinfo(511);
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
        -- tcp.close_network(client_id);
        logger(10, "Turning gps off");
        gps.gpsclose();
        logger(10, "Sleeping");
        logger(10, "GPS data thread sleeping for ", config.get_config_value("REPORT_INTERVAL") / 1000, " seconds");
        collectgarbage();
        thread.sleep(config.get_config_value("REPORT_INTERVAL"));
    end;
end;

local function cell_tick()
    logger(10, "Starting cell data tick function");
    local client_id = 2;
    logger(30, "Enc start, clock is: ", tostring(os.clock()))



    --[[key, enc_key = keygen.create_and_encrypt_key(128)
    logger(30, "Key is: ", key);
    logger(30, "Encrypted key is: ", enc_key);
    logger(30, "Key is: ", rsa.num_to_hex(key));
    logger(30, "Encrypted key is: ", rsa.num_to_hex(enc_key))
    logger(30, "Clock is: ", tostring(os.clock()))
    local key_data = {}
    key_data["key"] = key
    key_data["enc_key"] = enc_key]]--
    local key_data = true

    while (true) do
        logger(10, "Cell data thread waking up");

        if last_cell_report_has_expired() then
            --key_data["iv"] = rsa.bytes_to_num(keygen.create_key(128))
            --tcp.open_network(client_id);
            for i=1,1 do
                local cell_table = device.get_device_info_table()
                cell_table["extra_info"] = EXTRA_INFO
                --cell_table["key"] = rsa.num_to_hex(key)
                local encapsulated_payload = encaps.encapsulate_data(ati_string, cell_table, i, config.get_config_value("NMEA_LOOP_COUNT"));
                local result, headers, response = tcp.http_open_send_close(client_id, config.get_config_value("UPDATE_HOST"), config.get_config_value("UPDATE_PORT"), config.get_config_value("CELL_PATH"), encapsulated_payload, {}, key_data)
                logger(10, "Result is ", tostring(result), " and response is ", response);
                if result and headers["response_code"] == "200" then
                    update_last_cell_report();
                else
                    logger(30, "Update failed. Result is ", tostring(result), " and response is ", response);
                end;
                collectgarbage();
                thread.sleep(config.get_config_value("NMEA_SLEEP_TIME"));
            end;
            --tcp.close_network(client_id);
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
        firmware.check_firmware_and_maybe_update(imei, running_version)
        collectgarbage()
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
    if data["metric"] and data["value"] then
        logger(30, "Adding metric: ", data["metric"], " with value: ", data["value"])
        local metric = data["metric"]
        EXTRA_INFO[metric] = {}
        EXTRA_INFO[metric]["clock"] = os.clock()
        EXTRA_INFO[metric]["value"] = data["value"]
    end
end

local function process_out_cmd()
    local callback_table = {}
    callback_table[out_command.MESSAGE_TYPE_JSON] = parse_json_command
    out_command.wait_and_parse_loop(callback_table)
end

local function testing_thread()
    while ( true ) do
        local cell_table = device.get_device_info_table()
        local nmea_data = nmea.getinfo(511);
        local data = '{"version":"1","packet_number":4,"nmea":"$GPGSV,4,1,16,28,65,202,34,07,40,077,27,17,43,348,27,13,36,230,27*7B|$GPGSV,4,2,16,15,07,219,16,05,02,282,16,08,09,140,16,11,28,104,15*76|$GPGSV,4,3,16,19,23,341,15,30,68,118,14,01,16,084,,09,07,015,*72|$GPGSV,4,4,16,04,,,,32,,,,31,,,,29,,,*72|$GPGGA,031924.0,3348.948974,S,15112.009167,E,1,06,1.2,84.5,M,0,M,,*52|$GPVTG,NaN,T,,M,0.0,N,0.0,K,A*42|$GPRMC,031924.0,A,3348.948974,S,15112.009167,E,0.0,0.0,141017,,,A*70|$GPGSA,A,3,07,11,13,17,19,28,,,,,,,3.1,1.2,2.9*39|","device_info":"|Manufacturer: SIMCOM INCORPORATED|Model: SIMCOM_SIM5320A|Revision: SIM5320A_V1.5|IMEI: 012813008945935|+GCAP: +CGSM,+DS,+ES||OK|","packet_count":0}'
        if (nmea_data) then
            local encrypted = aes.encrypt("password", data, aes.AES128, aes.CBCMODE)
            local decrypted = aes.decrypt("password", encrypted, aes.AES128, aes.CBCMODE)
            if data ~= decrypted then
                logger(30, "Decryption failed")
                logger(30, data)
                logger(30, decrypted)
            end
            collectgarbage()

        end;

        thread.sleep(2000)

        --[[for j=1,127 do
            for i=1,63 do
                logger(30, "setting for device: ", j, " and register: ", i)
                i2c.write_i2c_dev(j, i, 101, 1)
                thread.sleep(100)
                local a, b, c, d = i2c.read_i2c_dev(j, i, 4)
                logger(30, "Read: ", a, " ", b, " ", c, " ", d)
                thread.sleep(100)
            end
        end]]--

        --[[spi.set_clk(0, 1, 1);
        logger(30, "set_cs")
        spi.set_cs(1, 1);
        logger(30, "set_freq")
        spi.set_freq(1000, 500000, 1000);
        logger(30, "set_num_bits")
        spi.set_num_bits(8, 0, 0);
        logger(30, "config_device")
        spi.config_device();
        spi.write(141, 42, 1)
        while true do
            for i=1,100 do
                spi.write(65, i, 1)
                a, b, c, d = spi.read(i, 1)
                logger(30, "a:", tostring(a), ",b:", tostring(b), ",c:", tostring(c), ",d:", tostring(d))
                thread.sleep(100)
            end
            spi.write(10, 101, 1)

            thread.sleep(1000)
        end]]--
    end
end

local start_threads = function (version)
    running_version = version;

    network_setup.set_network_from_sms_operator();
    vmsleep(2000);


    logger(10, "Start of start_threads")
    local gps_tick_thread = thread.create(gps_tick)
    local cell_tick_thread = thread.create(cell_tick)
    local firmware_check_thread = thread.create(get_firmware_version)
    local config_update_thread = thread.create(get_config)
    local out_cmd_thread = thread.create(process_out_cmd)
    local test_thread = thread.create(testing_thread)
    logger(10, "GPS tick thread: ", tostring(gps_tick_thread));
    logger(10, "cell_tick_thread: ", tostring(cell_tick_thread));
    logger(10, "Firmware check thread: ", tostring(firmware_check_thread));
    logger(10, "Config update thread: ", tostring(config_update_thread));
    logger(10, "Command parser thread: ", tostring(out_cmd_thread))
    logger(10, "Test thread: ", tostring(test_thread))
    local result
    -- thread.sleep(1000);
    logger(10, "Starting threads");
    result = thread.run(gps_tick_thread);
    logger(10, "GPS start thread result is ", tostring(result));
    result = thread.run(cell_tick_thread);
    logger(10, "Cell data start thread result is ", tostring(result));
    result = thread.run(firmware_check_thread);
    logger(10, "Firmware check start thread result is ", tostring(result));
    result = thread.run(config_update_thread);
    logger(10, "Config update start thread result is ", tostring(result));
    result = thread.run(out_cmd_thread);
    logger(10, "Command parser start thread result is ", tostring(result));
    result = thread.run(test_thread);
    logger(10, "Command parser start thread result is ", tostring(result));

    logger(10, "Threads are running");
    local counter = 0
    while thread.running(gps_tick_thread) and thread.running(cell_tick_thread) and thread.running(firmware_check_thread) and thread.running(config_update_thread) and thread.running(out_cmd_thread) and thread.running(test_thread) do
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
            thread.stop(out_cmd_thread);
            thread.stop(test_thread);
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
    logger(30, "Command parser thread running: ", thread.running(out_cmd_thread));
    logger(30, "Loop counter: ", counter);
    thread.sleep(2000)
    at.reset()
end;

_M.start_threads = start_threads

return _M