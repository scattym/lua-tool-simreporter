require("tests/device_emulation")
logging = require("logging")
local rsa = require("rsa_lib")
local logger = logging.create("rsatest", 30)

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

local private_exponent = "368d3109167f3557cf6d3377a9a50e"..
"0df3bef2aeb180e839e7abe1fce9ff"..
"77868829dfa5ff3b50857e3b83787d"..
"955f87e288bda4c1ae988a6385e49c"..
"1a2d5ac03099973888b8680675fbb3"..
"0a6975a7bcf5b8504b6dabac5e1692"..
"a6cb6014e17b5266653be36dd644a0"..
"7801cc23718413718d68c7bc303b51"..
"0eff352ffab9e8d1a09485627ee604"..
"f62b0e09779ac2dc61fecbb94f3ef8"..
"1c2851a3b17d1f257136ca992ddf96"..
"d1325e780c6c7d73adf93b5bbab8b9"..
"4bd8c9c0473097829e2db6d0382bca"..
"d83eef39b7ae8119f4bdee45da3302"..
"d8740acf759889867293b12c38b322"..
"9a82efb7e4ce62762ee21c380131ae"..
"d59cde8c976f502f322100b137473a"..
"19"

local create_key = function(bits)
    local bytes = math.floor(bits / 8)
    local key = ""
    for i=1,bytes do
        key = key .. string.char(math.random(0,255))
    end

    return key
end

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


local message, enc_key = create_and_encrypt_key(128)
print(message)
print(enc_key)
print(rsa.num_to_hex(enc_key))
print(rsa.num_to_hex(message))
local exponent = rsa.hex_to_num("10001")
local n_modulus = rsa.hex_to_num(modulus)
local private = rsa.hex_to_num(private_exponent)
local clear = rsa.mod_power(enc_key, private, n_modulus)
print(rsa.num_to_hex(enc_key))
print(rsa.num_to_hex(message))
print(rsa.num_to_hex(clear))