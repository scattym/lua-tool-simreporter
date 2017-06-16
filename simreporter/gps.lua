local gps = {}

local start = function(mode)
  if mode == 1 then
    print("GPS: Hot start")
    return 1
  elseif mode == 2 then
    print("GPS: old start")
    return 1
  end
  print("Invalid option")
  return 0
end
gps.start = start

local stop = function()
  print("GPS: stop")
  return 1
end
gps.stop = stop

local gpsinfo = function()
  local return_str = "lat,northsouth,long,eastwest,040777,utctime,altitude,speed,course\r\nampi/ampq"
  
  return return_str
end
gps.gpsinfo = gpsinfo


return gps