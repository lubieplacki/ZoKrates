from utils import *

def gen_invalidator_bits(private_key, secret):
    private_key_bits = int_to_bits(private_key, 256)
    secret_bits = int_to_bits(secret, 32)
    hash_bits = sha256(private_key_bits + secret_bits)
    return hash_bits

def gen_invalidator(private_key, secret):
    return bits_to_int(gen_invalidator(private_key, secret))

def gen_invalidator_proof(invalidator, private_key, secret):
    private_key_bits = int_to_bits(private_key, 256)
    secret_bits = int_to_bits(secret, 32)

    secret_input = [private_key] + [secret] + private_key_bits + secret_bits
    with open("proofs/invalidator/secret.input","w") as input_file:
        input_file.write("\n".join(secret_input))
    call("../../../target/release/zokrates compute-witness -a {} < secret.input > tmp".format(
    invalidator
    ),
    shell=True, cwd="proofs/invalidator")
    call("../../../target/release/zokrates generate-proof > invalidator.proof", shell=True, cwd="proofs/invalidator")
    with open('proofs/invalidator/invalidator.proof', 'r') as proof_file:
        proof_raw = proof_file.read()

    proof = raw_to_proof(proof_raw)
    return proof
