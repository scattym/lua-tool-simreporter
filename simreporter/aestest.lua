local aeslib = require("aes")

local data = "test data"
payload = aeslib.encrypt("password", data, aeslib.AES128, aeslib.CBCMODE)

print(payload)