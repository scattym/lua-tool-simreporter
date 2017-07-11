--local gps = require "gps"
--local nmea = require "nmea"
--local thread = require "thread"
collectgarbage();

local tcp = require "tcp_client"
local encaps = require "encapsulation"
--local nmea_event_handler = require "nmea_event_handler"
--local gps_timer = require "gps_timer"
local at = require "at_commands"
local network_setup = require "network_setup"

local NMEA_EVENT = 35;

local DEBUG = 1;
local recv_count = 0;
local GPS_LOCK_TIME = 60000;
local NMEA_SLEEP_TIME = 1000;
local REPORT_INTERVAL = 600000;
local NMEA_LOOP_COUNT = 5;
local MAIN_THREAD_SLEEP = 600000;
local MAX_MAIN_THREAD_LOOP_COUNT = 999999;

-- Drop intervals when in debug mode
if( DEBUG ) then
    GPS_LOCK_TIME = 10000;
    NMEA_SLEEP_TIME = 30000;
    REPORT_INTERVAL = 100000;
    NMEA_LOOP_COUNT = 50;
    MAIN_THREAD_SLEEP = 60000;
    MAX_MAIN_THREAD_LOOP_COUNT = 40;
end;

local ati_string = at.get_device_info();

function gps_tick()
    print("Starting gps tick function");
    local client_id = 1;
    while (true) do
        print("Turning gps on")
        gps.gpsstart(1);
        thread.sleep(GPS_LOCK_TIME);
        print("Requesting nmea data")
        tcp.open_network(client_id)
        for i=1,NMEA_LOOP_COUNT do
            local cell_table = {}
            cell_table["cpsi"] = at.get_cpsi();
            cell_table["cell_info"] = at.get_cell_info();
            cell_table["cbc"] = at.get_cbc();
            cell_table["cclk"] = at.get_cclk();
            cell_table["cgsn"] = at.get_cgsn();
            cell_table["cgmi"] = at.get_cgmi();
            cell_table["cgmm"] = at.get_cgmm();
            cell_table["cgmr"] = at.get_cgmr();
            cell_table["cops"] = at.get_cops();
            cell_table["ciccid"] = at.get_ciccid();
            cell_table["cspn"] = at.get_cspn();
            cell_table["cimi"] = at.get_cimi();
            cell_table["osclock"] = os.clock();
            -- print("cpsi, len=", string.len(cell_table["cpsi"]), "\r\n");
            -- print("cell_info, len=", string.len(cell_table["cell_info"]), "\r\n");
            local encapsulated_payload = encaps.encapsulate_data(ati_string, cell_table, i, NMEA_LOOP_COUNT);
            local result = tcp.http_open_send_close(client_id, "services.do.scattym.com", 65535, "/process_cell_update", encapsulated_payload);
            print("Result is ", tostring(result));
            local nmea_data = nmea.getinfo(63);
            if (nmea_data) then
                print("nmea_data, len=", string.len(nmea_data), "\r\n");
                local encapsulated_payload = encaps.encapsulate_nmea(ati_string, "nmea", nmea_data, i, NMEA_LOOP_COUNT)

                local result = tcp.http_open_send_close(client_id, "services.do.scattym.com", 65535, "/process_update", encapsulated_payload);
                print("Result is ", tostring(result));
            end;
            thread.sleep(NMEA_SLEEP_TIME);
        end;
        tcp.close_network(client_id)
        print("Turning gps off");
        gps.gpsclose();
        print("Sleeping");
        collectgarbage();
        thread.sleep(REPORT_INTERVAL);
    end;
end;

function start_threads()
    local gps_tick_thread = thread.create(gps_tick);
    print(tostring(gps_tick_thread));
    thread.sleep(1000);
    print("Starting threads");
    result = thread.run(gps_tick_thread);
    print("Start thread result is " .. tostring(result));

    print("Threads are running");
    local counter = 0
    while (thread.running(gps_tick_thread)) do
        print("Still running");
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

printdir(1);
network_setup.set_network_from_sms_operator()
vmsleep(15000);

thread_list = thread.list()
print("Thread list is " .. tostring(thread_list))

main_id = thread.identity();
print("main_id=", main_id, "\r\n");

collectgarbage();
start_threads();

print("exit main thread\r\n");

print(result)
