local gps = require "gps"
local nmea = require "nmea"
local thread = require "thread"
local tcp = require "tcp_client"

local NMEA_EVENT = 35

local recv_count = 0


result = gps.start(0x1)
while(recv_count < 50) do
  recv_count = recv_count + 1
  local nmea_info = nmea.getinfo(1)
  print("nmea_info=", nmea_info, "\r\n")
  -- vmsleep(10)
end


local recv_count = 0;
gps.start(1);
nmea.open(63);
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
        tcp.send_data("10.1.1.28", 5000, nmea_data)
        print(nmea_data);
        if (recv_count >= 100) then
          break;
        end;
      end;
    end;
end;
nmea.close();
gps.gpsclose();


print(result)