-------------------------------------------------
---      *** Crypto Test ***                  ---
-------------------------------------------------
--- Author:  Martin Huesser                   ---
--- Date:    2008-06-16                       ---
-------------------------------------------------

dofile("BitLibEmu.lua") --in case you do not have access to BitLib
dofile("Sha1.lua")

s = "The quick brown fox jumps over the lazy dog"
print("Sha1('"..s.."')")
print("Expected: 2fd4e1c67a2d28fced849ee1bb76e7391b93eb12")
print("Result  : "..Sha1(s))

--Generated with RSA.java, use <BigInteger>.toString(16) for hex output.
public  = "10001"

private = "816f0d36f0874f9f2a78acf5643acda3b59b9bcda66775b7720f57d8e9015536160e72"..
"8230ac529a6a3c935774ee0a2d8061ea3b11c63eed69c9f791c1f8f5145cecc722a220d2bc7516b6"..
"d05cbaf38d2ab473a3f07b82ec3fd4d04248d914626d2840b1bd337db3a5195e05828c9abf8de8da"..
"4702a7faa0e54955c3a01bf121"
modulus = "bfedeb9c79e1c6e425472a827baa66c1e89572bbfe91e84da94285ffd4c7972e1b9be3"..
"da762444516bb37573196e4bef082e5a664790a764dd546e0d167bde1856e9ce6b9dc9801e4713e3"..
"c8cb2f12459788a02d2e51ef37121a0f7b086784f0e35e76980403041c3e5e98dfa43ab9e6e85558"..
"c5dc00501b2f2a2959a11db21f"
modulus = "30820122300d06092a864886f70d01010105000382010f003082010a0282"..
"010100d32e93f7b2a2173637f50e67a6a7027bd4144bf619143615392d22"..
"b92a3ce4237ff20f699e225b667be7221d27f2c3c12f4f73d8e5800c5919"..
"19069b624508a9e6accde38e9a788d5fbd97ef8d03a9b31ebf4eedff55a5"..
"48b53cfffa41a09db5cfe8a18a928763fb1f17726d5e026d122f0ea1f90f"..
"aa66edbfd94c8521743aee2b7e24d277bdded7db44e2de1aabedcb7812f5"..
"d7a4499dd1e57ac5d081817f12813ea90cf16370c34cf60976ffa3d627b1"..
"3ffe4aa5ff61f786903ea015b2bd233135120f16c0c7f5ed4b02dc4e1259"..
"ce3e3d7caddb1cbeb921645f002ab8730d41efb19120cd31c4ae2bf2579a"..
"674871a258fa59d27f0756d9ffbebe361f3f150203010001"


function string.tohex(str)
    return (str:gsub('.', function (c)
        return string.format('%02X', string.byte(c))
    end))
end



math.randomseed( os.time() )

data = '{"test": 1, "test2": "2"}'
m_hex = data:tohex()
print(m_hex)

local big_int = require("BigInt")
-- m = BigInt_HexToNum("FEEDBEEFBADF00D")
m = big_int.hex_to_num(m_hex)
print("1")
d = big_int.hex_to_num(public)
print("2")
e = big_int.hex_to_num(private)
print("3")
n = big_int.hex_to_num(modulus)
print("4")
m = big_int.bigint(data)
print("4")
d = big_int.bigint(public)
print("4")
e = big_int.bigint(private)
print("4")
n = big_int.bigint(modulus)
print("4")
print("\nMessage = "..big_int.num_to_hex(m))
print("\nEncrypting... (this will take a few minutes)")
x = big_int.mod_power(m,d,n)
print("Encrypted Message = "..big_int.num_to_hex(x))
print("\nDecrypting... (very fast)")
y = big_int.mod_power(x,d,n)
print("Decrypted Message = "..big_int.num_to_hex(y))
