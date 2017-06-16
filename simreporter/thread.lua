local thread = {}
local NMEA_EVENT = 35

local waitevt = function(evt)
  os.execute("sleep " .. tonumber(1))
  return NMEA_EVENT
end

thread.waitevt = waitevt

return thread