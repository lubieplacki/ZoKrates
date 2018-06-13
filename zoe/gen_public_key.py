from subprocess import call
from utils import *

secret_key = raw_input("Please provide 32-character secret seed:\n")

secret_key_bits = string_to_bits(secret_key, 32)

print(secret_key)

secret_int = bits_to_int(secret_key_bits)
print("Your secret key:")
print(secret_int)

with open("secret.key","w") as sk_file:
    sk_file.write(str(secret_int))

#params = "{} {}".format(" ".join([str(secret_key_bits[i]) for i in range(0, 256)]), " ".join(["0" for i in range(0, 256)]))

public_int = bits_to_int(sha256(secret_key_bits))

print("Your public key:")
print(public_int)
with open("public.key","w") as pb_file:
    pb_file.write(str(public_int))
