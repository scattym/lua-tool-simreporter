require("tests/device_emulation")
bit32.band(1, 1)
local logging = require("logging")
local aes = require("aes")
local rsa_lib = require("rsa_lib")
local keygen = require("keygen")
local json = require("json")
local util = require("util")
local logger = logging.create("aes_test", 30)

local key_hex = "5e884898da28047151d0e56f8dc62927"
local key_raw = aes.hexToBytes(key_hex)

local clear = '{"TCP_SLEEP_TIME": 30000, "FIRMWARE_HOST": "services.pts.scattym.com", "NMEA_SLEEP_TIME": 30000, "REPORT_INTERVAL": 3600000, "GPS_LOCK_CHECK_MAX_LOOP": 1, "CELL_THREAD_SLEEP_TIME": 30000, "MQ_HOST": "mqtt.pts.scattym.com", "UPDATE_HOST": "services.pts.scattym.com", "SOCK_HOST": "scs.pts.scattym.com", "MAIN_THREAD_SLEEP": 30000, "GPS_LOCK_CHECK_SLEEP_TIME": 20000, "GPS_PATH": "/v2/process_update", "MAX_MAIN_THREAD_LOOP_COUNT": 200000, "ENABLE_TCP": "true", "MIN_REPORT_TIME": 120, "CONFIG_SLEEP_TIME": 60000, "checksum": "fd411cf937c8f57d99895fcd3a3c6073f4665b95cdb5fe0ef98d1f6f110fab74", "UPDATE_PORT": 65535, "NMEA_LOOP_COUNT": 0, "FIRMWARE_SLEEP_TIME": 60000, "CELL_PATH": "/v2/process_cell_update"}'
local enc = aes.encrypt("password", clear, aes.AES128, aes.CBCMODE)
print("Encrypted type is ", type(enc))
print(aes.toHexString(enc))

print("DECRYPT1")
print(aes.decrypt("password", enc, aes.AES128, aes.CBCMODE))
assert(aes.decrypt("password", enc, aes.AES128, aes.CBCMODE) == clear)


print("DECRYPT2")
enc = aes.encrypt("password", clear, aes.AES128, aes.CBCMODE)
key_raw = aes.hexToBytes(key_hex)
print(type(key_raw))
print(aes.decrypt_raw_key(key_raw, enc, aes.AES128, aes.CBCMODE))
assert(aes.decrypt_raw_key(key_raw, enc, aes.AES128, aes.CBCMODE) == clear)
print("DONE")

-- Test generated key from hex
local key_hex = "11223344556677888877665544332212"
local key_raw = aes.hexToBytes(key_hex)

print("Key raw type is ", type(key_raw))
print("Encrypting string")
clear = '{"imei": "770704079425", "nmea": "$GPGGA,190348.0,3348.947890,S,15112.010303,E,1,05,1.8,62.8,M,24.0,M,,*70|$GPVTG,188.9,T,188.9,M,0.0,N,0.0,K,A*23|$GPRMC,190348.0,A,3348.947890,S,15112.010303,E,0.0,188.9,140318,A*73|$GPGSA,A,2,13,15,17,19,28,,,,,,,,2.0,1.8,0.9*33|"}'
enc = aes.encrypt_raw_key(key_raw, clear, aes.AES128, aes.CBCMODE)

print(aes.toHexString(enc))
assert(aes.toHexString(enc) == "FC821FF63D27A79CF51B16A916E5B077FFE3278CF4C7938DAFC25096782BC63D400385A14F50D7E16FF7D3F7F08241E22D77576B07423F36DE7E86F2A399701877CDE30671C7C3197CF548A49E621D90B37D9ACBE0AB39F7620895C00394E67E325BFFCCEF966AB30CC0EEE38C5E6A2937192A7684E00829BEEB2C7E22A9090DD793537460CAEC9F63FDF9508CB8E5578C3DCE9C4CEBC0B8E75664C10CB57FC2D6C1BCA803724EC6C6D66DF0E8B2197C47951BCF1BECAE0C8D9DEF10492CE4E9FBA8501DDF4C01DB57A7B07464FB40F5276358C52B4D4E7F30A6AD74B326530B0C77BDD91B47A42F6FD426D3A15FBB7965D54F7B1DD31498F2D69EADF6A9ED0777B80E04A2D5796D8697D00FF282ECA8")

local decrypted = aes.decrypt_raw_key(key_raw, enc, aes.AES128, aes.CBCMODE)
print(decrypted)

assert(decrypted == '{"imei": "770704079425", "nmea": "$GPGGA,190348.0,3348.947890,S,15112.010303,E,1,05,1.8,62.8,M,24.0,M,,*70|$GPVTG,188.9,T,188.9,M,0.0,N,0.0,K,A*23|$GPRMC,190348.0,A,3348.947890,S,15112.010303,E,0.0,188.9,140318,A*73|$GPGSA,A,2,13,15,17,19,28,,,,,,,,2.0,1.8,0.9*33|"}')

-- Test key generated from keygen
local raw_key, enc_login_message = keygen.create_and_encrypt_key("770704079425", 16)
print(raw_key)
print(util.tohex(raw_key))

print("Raw key type is ", type(raw_key))
print("Message type is ", type(enc_login_message))
print(util.tohex(enc_login_message))
print("First index type is ", type(enc_login_message[1]))

local login_payload = util.tohex(enc_login_message)
local as_str = util.fromhex(login_payload)
print(type(as_str))
print("As a string", as_str)

local iv = aes.getRandomBytes(16)
print(iv)
print(type(iv))
print(util.tohex(iv))

enc = aes.encrypt_raw_key(raw_key, clear, aes.AES128, aes.CBCMODE, iv)
clear = aes.decrypt_raw_key(raw_key, enc, aes.AES128, aes.CBCMODE, iv)
print(enc)
print(clear)