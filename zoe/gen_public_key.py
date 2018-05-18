from subprocess import call
import json
secret_key = raw_input("Please provide 32-character secret key:\n")
secret_key = secret_key[0:32]

def bits_to_int(bits):
    res = 0
    for i in range(0, len(bits)):
        res = res * 2 + bits[len(bits) - 1 - i]
    return res

print secret_key
secret_key_bits = []
for i in range(0, 32):
    x = 0
    if i < len(secret_key):
        x = ord(secret_key[i])
    for j in range(0, 8):
        secret_key_bits.append(x % 2)
        x = x / 2

params = "{} {}".format(" ".join([str(secret_key_bits[i]) for i in range(0, 256)]), " ".join(["0" for i in range(0, 256)]))
call("cd proofs/sha256", shell=True)
call("../../../target/release/zokrates compute-witness -a {}".format(params), shell=True)
call("cd ../..", shell=True)
print "Your secret key:"
secret_int = bits_to_int(secret_key_bits)
print secret_int

with open("secret.key","w") as sk_file:
    sk_file.write(str(secret_int))
witness = {}
with open('proofs/sha256/witness', 'r') as witness_file:
    witness_output = (witness_file.read()).split()
    for i in range(0, len(witness_output), 2):
        witness[witness_output[i]] = witness_output[i+1]

public_key_bits = []
for i in range(0, 256):
    public_key_bits.append(int(witness["~out_{}".format(i)]))

public_int = bits_to_int(public_key_bits)

print "Your public key:"
print public_int
with open("public.key","w") as pb_file:
    pb_file.write(str(public_int))
