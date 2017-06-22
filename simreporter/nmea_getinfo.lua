--local gps = require "gps"
--local nmea = require "nmea"
--local thread = require "thread"
local tcp = require "tcp_client"
--local nmea_event_handler = require "nmea_event_handler"
--local gps_timer = require "gps_timer"

NMEA_EVENT = 35

local recv_count = 0

local encapsulate_nmea = function(nmea, iteration, count)
  local before = "{ \"version\" : 1, "
  before = before .. "\"nmea_number\" : " .. tostring(iteration) .. ", "
  before = before .. "\"nmea_total\" : " .. tostring(count) .. ", "
  print("Before is " .. before .. "\r\n")
  local payload = "\"nmea\" : \"" .. tostring(nmea) .. "\" "
  print("Payload is " .. payload .. "\r\n")
  local after = "}"
  print("After is " .. after .. "\r\n")
  return before .. payload .. after
end

function gps_tick()
  print("Starting gps tick function");
  while (true) do
    print("Turning gps on")
    gps.gpsstart(1);
    thread.sleep(60000);
    print("Requesting nmea data")
    local loop = 5
    for i=1,loop do
      local nmea_data = nmea.getinfo(63);
      if (nmea_data) then
        print("nmea_data, len=", string.len(nmea_data), "\r\n");
        local encapsulated_payload = encapsulate_nmea(nmea_data, i, loop)
        local client_id = 1;
        local result = tcp.open_send_close_tcp(client_id, "theforeman.do.scattym.com", 65535, encapsulated_payload);
        print("Result is ", tostring(result));
      end;
      thread.sleep(1000);
    end;
    print("Turning gps off");
    gps.gpsclose();
    print("Sleeping");
    collectgarbage();
    thread.sleep(300000);
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
    thread.sleep(10000);
    counter = counter+1;
    if( counter > 1000) then
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