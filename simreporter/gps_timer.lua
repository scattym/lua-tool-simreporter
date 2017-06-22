
local gps_timer = {}

local gps_tick = function()
  print("Starting gps tick function");
  local recv_count=0;
  vmstarttimer(2,2000, 1);
  while (true) do
    local evt, evt_p1, evt_p2, evt_p3, evt_clock = thread.waitevt(999999);
    print("Turning gps on")
    gps.gpsstart(1);
    nmea.start(63);
    thread.sleep(1000);
    print("Turning gps off")
    nmea.stop();
    gps.gpsclose();
    recv_count = recv_count+1;
    if(recv_count > 10) then
      break;
    end;
  end;
end;

gps_timer.gps_tick = gps_tick;

return gps_timer;