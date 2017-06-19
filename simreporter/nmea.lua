local nmea = {}

local MODE = 0

local getinfo = function(filter)
  local return_str = ""
  
  if bit32.band(filter, 0x1) == 0x1 then
    print("NMEA: GGA")
    return_str = return_str .. "$GPGGA,092751.000,5321.6802,N,00630.3371,W,1,8,1.03,61.7,M,55.3,M,,*75\r\n"
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
    return_str = return_str .. "$GPVTG,,T,,M,0.00,N,0.00,K*4E\r\n"
  end
  
  if bit32.band(filter, 0x20) == 0x20 then
    print("NMEA: PSTIS")
    return_str = return_str .. "$PSTIS,*61\r\n"
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
  print("NMEA: recv")
  return getinfo(MODE)
end
nmea.recv = recv
 
local close = function()
  print("NMEA: close")
  return 0
end
nmea.close = close

return nmea