--local gps = require "gps"
--local nmea = require "nmea"
--local thread = require "thread"
local tcp = require "tcp_client"
local encaps = require "encapsulation"
--local nmea_event_handler = require "nmea_event_handler"
--local gps_timer = require "gps_timer"

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
  GPS_LOCK_TIME = 40000;
  NMEA_SLEEP_TIME = 3000;
  REPORT_INTERVAL = 300000;
  NMEA_LOOP_COUNT = 5;
  MAIN_THREAD_SLEEP = 60000;
  MAX_MAIN_THREAD_LOOP_COUNT = 10;
end;

function gps_tick()
  print("Starting gps tick function");
  while (true) do
    print("Turning gps on")
    gps.gpsstart(1);
    thread.sleep(GPS_LOCK_TIME);
    print("Requesting nmea data")
    for i=1,NMEA_LOOP_COUNT do
      local nmea_data = nmea.getinfo(63);
      if (nmea_data) then
        print("nmea_data, len=", string.len(nmea_data), "\r\n");
        local encapsulated_payload = encaps.encapsulate_nmea(nmea_data, i, NMEA_LOOP_COUNT)
        local client_id = 1;
        local result = tcp.open_send_close_tcp(client_id, "theforeman.do.scattym.com", 65535, encapsulated_payload);
        print("Result is ", tostring(result));
      end;
      thread.sleep(NMEA_SLEEP_TIME);
    end;
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

thread_list = thread.list()
print("Thread list is " .. tostring(thread_list))

main_id = thread.identity();
print("main_id=", main_id, "\r\n");

collectgarbage();
start_threads();

print("exit main thread\r\n");

print(result)