--local gps = require "gps"
--local nmea = require "nmea"
--local thread = require "thread"
local tcp = require "tcp_client"

local nmea_event_handler = {}

local NMEA_EVENT = 35

local recv_count = 0

local encapsulate_nmea = function(nmea, count)
  local before = "{ \"version\" : 1, \"lock_count\" : "
  print("Before is " .. before .. "\r\n")
  before = before .. "\"" .. tostring(count) .. "\","
  print("Before is " .. before .. "\r\n")
  local payload = "\"nmea\" : \"" .. tostring(nmea) .. "\","
  print("Payload is " .. payload .. "\r\n")
  local after = "}"
  print("After is " .. after .. "\r\n")
  return before .. payload .. after
end
  

--[[result = gps.gpsstart(0x1)
while(recv_count < 5) do
  print("About to sleep\r\n")
  vmsleep(10000)
   recv_count = recv_count + 1
   local nmea_info = nmea.getinfo(63)
   print("nmea_info=", nmea_info, "\r\n")
  local encapsulated_payload = encapsulate_nmea(nmea_info, recv_count)
   tcp.send_data("theforeman.do.scattym.com", 65535, encapsulated_payload)
end
gps.gpsclose();]]


local nmea_evh = function(var1, var2, var3)
  print("nmea evh called");
  print("thread id=", thread.identity(), "\r\n");
  printdir(1);
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
    if(recv_count > 2) then
      print("Event process limit. Exiting")
      break;
    end;
  end;
end;
nmea_event_handler.nmea_evh = nmea_evh

--[[
while (true) do
  local recv_count = 0;
  local evt, evt_p1, evt_p2, evt_p3, evt_clock = thread.waitevt(999999);
    if (evt and evt == NMEA_EVENT) then
      local nmea_data = nmea.recv(0);
      if (nmea_data) then
        recv_count = recv_count + 1;
        print("nmea_data, len=", string.len(nmea_data), "\r\n");
        tcp.send_data("theforeman.do.scattym.com", 65535, nmea_data)
        print(nmea_data);
      end;
    end;
end;]]

return nmea_event_handler;