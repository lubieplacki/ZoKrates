from subprocess import call
from utils import *
from Crypto import Random
from Crypto.PublicKey import RSA

def gen_keys():
    secret_key = input("Please provide 32-character secret seed:\n")

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

    modulus_length = 256*8
    rsa_private_key = RSA.generate(modulus_length, Random.new().read)
    rsa_public_key = rsa_private_key.publickey()
    print("Your private encryption key:")
    print(rsa_private_key.exportKey().decode('utf-8'))
    with open("rsa_private.key","w") as pb_file:
        pb_file.write(rsa_private_key.exportKey().decode('utf-8'))
    print("Your public encryption key:")
    print(rsa_public_key.exportKey().decode('utf-8'))
    with open("rsa_public.key","w") as pb_file:
        pb_file.write(rsa_public_key.exportKey().decode('utf-8'))
    return secret_int, public_int, rsa_private_key, rsa_public_key

def load_keys():
    with open("secret.key","r") as pb_file:
        secret_int = pb_file.read()
    with open("public.key","r") as pb_file:
        public_int = pb_file.read()
    with open("rsa_private.key","r") as pb_file:
        rsa_private_key = pb_file.read()
    with open("rsa_public.key","r") as pb_file:
        rsa_public_key = pb_file.read()

    return secret_int, public_int, rsa_private_key, rsa_public_key
