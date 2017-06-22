--local gps = require "gps"
--local nmea = require "nmea"
--local thread = require "thread"
local tcp = require "tcp_client"

local NMEA_EVENT = 35

local recv_count = 0

local encapsulate_nmea = function(nmea, count)
  local before = "{ \"version\" : 1, \"lock_count\" : "
  print("Before is " .. before .. "\r\n")
  before = before .. "\"" .. tostring(count) .. "\","
  print("Before is " .. before .. "\r\n")
  local time = "\"osclock\" : \"" .. os.clock() .. "\","
  local payload = "\"nmea\" : \"" .. tostring(nmea) .. "\","
  print("Payload is " .. payload .. "\r\n")
  local after = "}"
  print("After is " .. after .. "\r\n")
  return before .. time .. payload .. after
end
  

result = gps.gpsstart(0x1)
while(recv_count < 5) do
  print("About to sleep\r\n")
  vmsleep(10000)
   recv_count = recv_count + 1
   local nmea_info = nmea.getinfo(63)
   print("nmea_info=", nmea_info, "\r\n")
  local encapsulated_payload = encapsulate_nmea(nmea_info, recv_count)
   tcp.send_data("theforeman.do.scattym.com", 65535, encapsulated_payload)
end
gps.gpsclose();

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