
local _M = {}

local logging = require("logging")
local logger = logging.create("keygen", 30)

local modulus = "00aa302e17a90a9689fbe4b05f4fb2"..
"19cc793152d9def84e9cbd8b7e651f"..
"68b648cc3fce4721717d336c758be9"..
"8a85746ea109f55e08ca6b46dd61bf"..
"b454fb3f15611623f9ceff6975a8f1"..
"34bb6267f6f715caea895d65dde008"..
"c881ee8f4a7d7f87858be42c9f90b1"..
"e8002007154f50c56418effd22c476"..
"9d28e9bcd7cbc48658007cf363596b"..
"fcb40b7c1588dd27f7f6fcd44dc40f"..
"b4896235d579cca7c0f140bc3a99b7"..
"f84b9d64d137c5c499534504ac60d2"..
"71e8d396b641274f6644f65cf7b22e"..
"24c35834f59039bc7168ad7e3e999a"..
"6c51bde9ba7d3acc3afffdf6f729ea"..
"013d993680aa7c1b02728d4447f4ec"..
"a4400b0354ac8c3ab37f7f616e3a2d"..
"da5b"

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

    return key
end
_M.create_and_encrypt_key = create_and_encrypt_key

return _M