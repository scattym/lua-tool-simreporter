
import Crypto
from Crypto.PublicKey import RSA
from Crypto import Random
import ast
from Crypto.Util.number import bytes_to_long, long_to_bytes
import binascii
import hashlib
from base64 import b64decode
from base64 import b64encode
import binascii

from Crypto import Random
from Crypto.Cipher import AES

f = open('/tmp/test', 'r')
message = f.read()
print len(message)
data = binascii.unhexlify(message)

unpad = lambda s: s[:-ord(s[len(s) - 1:])]

# 5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8


def decrypt(enc):

    print binascii.hexlify(bytearray(enc))
    iv = enc[:16]
    iv = binascii.unhexlify("00000000000000000000000000000000")
    sha256 = hashlib.sha256()
    sha256.update("password")
    key = sha256.digest()[0:16]
    # print(sha256.hexdigest())
    cipher = AES.new(key, AES.MODE_CBC, iv)
    # clear = unpad(cipher.decrypt(enc[16:]))
    clear_padded = cipher.decrypt(enc)
    print clear_padded
    clear = unpad(clear_padded)
    binascii.hexlify(bytearray(clear))
    # print("Clear is %s" % clear)
    return clear.decode('utf8')

print decrypt(data)
