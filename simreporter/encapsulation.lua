

local _M = {}

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

_M.encapsulate_nmea = encapsulate_nmea

return _M