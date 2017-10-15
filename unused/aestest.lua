local aeslib = require("aes")

--[[local data = "test data"
payload = aeslib.encrypt("password", data, aeslib.AES128, aeslib.CBCMODE)

print(payload)
unencrypted = aeslib.decrypt("password", payload, aeslib.AES128, aeslib.CBCMODE)
print(unencrypted)]]--
local function bytesToHex(bytes)
	local hexBytes = ""

	for i,byte in ipairs(bytes) do
		hexBytes = hexBytes .. string.format("%02x ", byte)
	end

	return hexBytes
end
   function hex_dump(buf)
      for i=1,math.ceil(#buf/16) * 16 do
         if (i-1) % 16 == 0 then io.write(string.format('%08X  ', i-1)) end
         io.write( i > #buf and '   ' or string.format('%02X ', buf:byte(i)) )
         if i %  8 == 0 then io.write(' ') end
         if i % 16 == 0 then io.write( buf:sub(i-16+1, i):gsub('%c','.'), '\n' ) end
      end
   end

local data = '{"version":"1","packet_number":4,"nmea":"$GPGSV,4,1,16,28,65,202,34,07,40,077,27,17,43,348,27,13,36,230,27*7B|$GPGSV,4,2,16,15,07,219,16,05,02,282,16,08,09,140,16,11,28,104,15*76|$GPGSV,4,3,16,19,23,341,15,30,68,118,14,01,16,084,,09,07,015,*72|$GPGSV,4,4,16,04,,,,32,,,,31,,,,29,,,*72|$GPGGA,031924.0,3348.948974,S,15112.009167,E,1,06,1.2,84.5,M,0,M,,*52|$GPVTG,NaN,T,,M,0.0,N,0.0,K,A*42|$GPRMC,031924.0,A,3348.948974,S,15112.009167,E,0.0,0.0,141017,,,A*70|$GPGSA,A,3,07,11,13,17,19,28,,,,,,,3.1,1.2,2.9*39|","device_info":"|Manufacturer: SIMCOM INCORPORATED|Model: SIMCOM_SIM5320A|Revision: SIM5320A_V1.5|IMEI: 012813008945935|+GCAP: +CGSM,+DS,+ES||OK|","packet_count":0}'
for i=1,100000 do
    local to_encrypt = data
    local payload = aeslib.encrypt("password", to_encrypt, aeslib.AES128, aeslib.CBCMODE)
    local unencrypted = aeslib.decrypt("password", payload, aeslib.AES128, aeslib.CBCMODE)
    if tostring(to_encrypt) ~= tostring(unencrypted) then
        print("Not same data. Length: ", i)
        print("Clear text: >" .. to_encrypt .. "<")
        print("Decrypted:  >" ..  unencrypted .. "<")
        print(hex_dump(to_encrypt))
        print(hex_dump(unencrypted))

    end
end
