
local _M = {}

local logging = require("logging")
local rsa = require("rsa_lib")
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

local create_key = function(bits)
    local bytes = math.floor(bits / 8)
    local key = ""
    for i=1,bytes do
        key = key .. string.char(math.random(0,255))
    end

    return key
end
_M.create_key = create_key

local create_and_encrypt_key = function(bits)
    local key = create_key(128)
    logger(30, "Key generation complete.")
    local message = rsa.bytes_to_num(key) -- message is the key
    logger(30, "Key is " .. rsa.num_to_hex(message))
    logger(30, "Calculated message as big int: " .. tostring(message))
    local exponent = rsa.hex_to_num("10001")
    logger(30, "Calculated exponent")
    local n_modulus = rsa.hex_to_num(modulus)
    logger(30, "Calculated modulus")

    local enc_key = rsa.mod_power(message, exponent, n_modulus)
    logger(30, "Encrypted key: ", rsa.num_to_hex(enc_key))

    return message, enc_key
end
_M.create_and_encrypt_key = create_and_encrypt_key

return _M