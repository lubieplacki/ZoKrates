from src.utils import *
from subprocess import call

def gen_commitment_bits(public_key, secret, value):
    public_key_bits = int_to_bits(public_key, 256)
    value_bits = int_to_bits(value, 32)
    secret_bits = int_to_bits(secret, 32)
    hash_bits = sha256(public_key_bits + value_bits + secret_bits)
    return hash_bits

def gen_commitment(public_key, secret, value):
    return bits_to_int(gen_commitment_bits(public_key, secret, value))

def gen_commitment_proof(commitment, value, secret, public_key):
    public_key_bits = int_to_bits(public_key, 256)
    value_bits = int_to_bits(value, 32)
    secret_bits = int_to_bits(secret, 32)
    secret_input = [secret] + [public_key] + value_bits + secret_bits + public_key_bits
    secret_input = " ".join([str(x) for x in secret_input])
    call("../../../target/release/zokrates compute-witness -a {} {} {} > tmp".format(
    commitment,
    value,
    secret_input
    ),
    shell=True, cwd="proofs/commitment")
    call("../../../target/release/zokrates generate-proof > commitment.proof", shell=True, cwd="proofs/commitment")
    with open('proofs/commitment/commitment.proof', 'r') as proof_file:
        proof_raw = proof_file.read()

    proof = raw_to_proof(proof_raw)
    return proof
