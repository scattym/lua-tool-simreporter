--local gps = require "gps"
--local nmea = require "nmea"
--local thread = require "thread"
local tcp = require "tcp_client"
local encaps = require "encapsulation"

local NMEA_EVENT = 35

local recv_count = 0

local CLIENT_ID = 1
local LOOP_COUNT = 5
  
printdir(1)

result = gps.gpsstart(0x1)
while(recv_count < LOOP_COUNT) do
   print("About to sleep\r\n")
   vmsleep(2000)
   recv_count = recv_count + 1
   local nmea_info = nmea.getinfo(63)
   print("nmea_info=", nmea_info, "\r\n")
   local encapsulated_payload = encaps.encapsulate_nmea(nmea_info, recv_count, LOOP_COUNT)
   local send_result = tcp.open_send_close_tcp(CLIENT_ID, "theforeman.do.scattym.com", 65535, encapsulated_payload);
   print("Result is ", tostring(send_result));
end
gps.gpsclose();

print(result);