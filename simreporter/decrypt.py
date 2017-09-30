
import Crypto
from Crypto.PublicKey import RSA
from Crypto import Random
import ast
from Crypto.Util.number import bytes_to_long, long_to_bytes
import binascii


f = open("/Users/matt/.ssh/simcom.private", "r")
key = RSA.importKey(f.read())

print key

random_generator = Random.new().read
# key = RSA.generate(1024, random_generator) #generate pub and priv key

publickey = key.publickey() # pub key export for exchange

f = open('/tmp/enckey.bin', 'r')
message = f.read()


decrypted = key.decrypt(message)

print 'decrypted', decrypted
print binascii.hexlify(decrypted)


