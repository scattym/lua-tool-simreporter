local nmea = {}

local MODE = 0

local getinfo = function(filter)
  local return_str = ""
  
  if bit32.band(filter, 0x1) == 0x1 then
    print("NMEA: GCA")
    return_str = return_str .. "nmea: unknown string\r\n"
  end
  
  if bit32.band(filter, 0x2) == 0x2 then
    print("NMEA: RMC")
    return_str = return_str .. "$GPRMC,000006,V,5907.1920,N,01222.9510,E,0.0,0.0,010200,1.1,E*6B\r\n"
  end
  
  if bit32.band(filter, 0x4) == 0x4 then
    print("NMEA: GSV")
    return_str = return_str .. "$GPGSV,1,1,0*49\r\n"
  end
  
  if bit32.band(filter, 0x8) == 0x8 then
    print("NMEA: GSA")
    return_str = return_str .. "$GPGSA,A,1,,,,,,,,,,,,,,99.00,99.00,0.00*2C\r\n"
  end
  
  if bit32.band(filter, 0x10) == 0x10 then
    print("NMEA: VTG") 
    return_str = return_str .. "nmea: unknown string\r\n"
  end
  
  if bit32.band(filter, 0x20) == 0x20 then
    print("NMEA: PSTIS")
    return_str = return_str .. "nmea: unknown string\r\n"
  end

  return return_str
end
nmea.getinfo = getinfo

local open = function(filter)
  MODE = filter
  return 0
end
nmea.open = open
  

local recv = function(wait)
  return getinfo(MODE)
end
nmea.recv = recv
 

return nmea