--local gps = require "gps"
--local nmea = require "nmea"
--local thread = require "thread"
local tcp = require "tcp_client"
--local nmea_event_handler = require "nmea_event_handler"
--local gps_timer = require "gps_timer"

local NMEA_EVENT = 35

local recv_count = 0

--nmea_evh = nmea_event_handler.nmea_evh;

local encapsulate_nmea = function(nmea, count)
  local before = "{ \"version\" : 1, \"lock_count\" : "
  print("Before is " .. before .. "\r\n")
  before = before .. "" .. tostring(count) .. ","
  print("Before is " .. before .. "\r\n")
  local payload = "\"nmea\" : \"" .. tostring(nmea) .. "\","
  print("Payload is " .. payload .. "\r\n")
  local after = "}"
  print("After is " .. after .. "\r\n")
  return before .. payload .. after
end

function nmea_evh()
  print("nmea evh called");
  print("thread id=", thread.identity(), "\r\n");
  print("Starting nmea event handler");
  local recv_count = 0;
  --vmstarttimer(1,2000, 1);
  while (true) do
    local evt, evt_p1, evt_p2, evt_p3, evt_clock = thread.waitevt(999999);
    print ("In nmea event handler")
    if (evt and evt == NMEA_EVENT) then
      print ("Is an nmea event")
      for i=1,2 do
        local nmea_data = nmea.getinfo(63);
        if (nmea_data) then
          print("nmea_data, len=", string.len(nmea_data), "\r\n");
          local encapsulated_payload = encapsulate_nmea(nmea_data, i)
          tcp.send_data("theforeman.do.scattym.com", 65535, encapsulated_payload)
          print(encapsulated_payload);
        end;
      end;
      recv_count = recv_count + 1;
     end;
    if(recv_count > 100) then
      print("Event process limit. Exiting")
      break;
    end;
  end;
end;

function gps_tick()
  print("Starting gps tick function");
  local recv_count=0;
  vmstarttimer(2,2000, 1);
  while (true) do
    -- local evt, evt_p1, evt_p2, evt_p3, evt_clock = thread.waitevt(999999);
    print("Turning gps on")
    gps.gpsstart(1);
    nmea.open(63);
    thread.sleep(10000);
    print("Turning gps off")
    nmea.close();
    gps.gpsclose();
    recv_count = recv_count+1;
    if(recv_count > 100) then
      break;
    end;
  end;
end;

function start_threads()
  local nmea_evh_thread = thread.create(nmea_evh);
  local gps_tick_thread = thread.create(gps_tick);
  print("Starting threads");

  thread.run(nmea_evh_thread);
  thread.setevt(nmea_evh_thread, NMEA_EVENT);
  thread.run(gps_tick_thread);

  print("Threads are running");
  while (thread.running(nmea_evh_thread) or thread.running(gps_tick_thread)) do
    print("Still running");
    thread.sleep(10000);
  end;
  print("all sub-threads ended\r\n");
end;

function sio_send(cmd)
  print(">>>>>>>>>>>>>>", cmd);
  result = sio.send(cmd);
  return result;
end;

function sio_recv(timeout)  
  local rsp = sio.recv(timeout);
  if (rsp) then
    print("<<<<<<<<<<<<<<", rsp);
  end;
  return rsp;
end;


printdir(1);
collectgarbage();

thread_list = thread.list()
print(thread_list)
--sio_send("ATE0\r\n")
--rsp = sio_recv(5000);

--global_value_test = 0;
main_id = thread.identity();
print("main_id=", main_id, "\r\n");

--nmea_event_handler.nmea_evh();

start_threads();

sio_send("ATI\r\n")
rsp = sio_recv(5000);
print(rsp);

--sio_send("ATE1\r\n")
--rsp = sio_recv(5000);
print("exit main thread\r\n");

--local recv_count = 0;
--gps.gpsstart(1);
--[[nmea.open(63);
while (true) do
  local evt, evt_p1, evt_p2, evt_p3, evt_clock = thread.waitevt(999999);
    if (evt and evt == NMEA_EVENT) then
      local nmea_data = nmea.recv(0);
      if (nmea_data) then
        recv_count = recv_count + 1;
        print("nmea_data, len=", string.len(nmea_data), "\r\n");
        for s in string.gmatch(nmea_data, ".*$") do
          print("Line based data to follow")
          print(s)
            -- do stuff with line
        end
        tcp.send_data("theforeman.do.scattym.com", 65535, nmea_data)
        print(nmea_data);
        if (recv_count >= 5) then
          break;
        end;
      end;
    end;
end;
nmea.close();
--gps.gpsclose();]]


print(result)