
local _M = {}

local logging = require("logging")
local rsa = require("rsa_lib")
local aes = require("aes")
local json = require("json")
local util = require("util")
local logger = logging.create("keygen", 30)

local modulus = "0099e9d73b5ce5ae593212223a25e3"..
"0b5dfc5b3432620feef2d1d761392b"..
"932bdb94da233dafef460321b2960a"..
"8e86a556ffb929f9a1da72cd509a7f"..
"c006d2df50cacfafd966aa9319436d"..
"750f6a344f1264117b50c4bb1f9b8f"..
"0fc01c228262fd0d50550935850cb0"..
"df57043b221ef6d935370b4c1baf06"..
"e241c06b78204ed527"

local function bytestostring(bytes, bytes_length)
  local s = ""
  for i = 1, bytes_length do
    s = s .. string.byte(bytes[i]) -- '..' create new string. Expensive!!
  end
  return s
end

local create_and_encrypt_key = function(imei, bytes)
    local raw_key = aes.getRandomString(bytes)
    -- logger(30, "Raw key is", aes.toHexString(raw_key))
    local key_encoded = base64.encode(raw_key)
    local random_encoded = base64.encode(aes.getRandomString(bytes))
    logger(20, "Key generation complete.")

    local login_message = {}
    login_message["r"] = tostring(random_encoded)
    login_message["i"] = tostring(imei)
    login_message["sk"] = tostring(key_encoded)
    local json_message = json.encode(login_message)
    logger(20, "json message raw ", json_message)

    local message = rsa.bytes_to_num(json_message) -- message is the key
    logger(10, "json message hex is " .. rsa.num_to_hex(message))
    logger(0, "Calculated message as big int: " .. tostring(message))
    local exponent = rsa.hex_to_num("10001")
    logger(20, "Calculated exponent")
    local n_modulus = rsa.hex_to_num(modulus)
    logger(20, "Calculated modulus")

    local enc_login_message = rsa.mod_power(message, exponent, n_modulus)
    logger(10, "Encrypted key: ", rsa.num_to_hex(enc_login_message))

    local raw_key_bytes = { string.byte(raw_key, 1,-1) }
    return raw_key_bytes, rsa.num_to_hex(enc_login_message)
end
_M.create_and_encrypt_key = create_and_encrypt_key

return _M