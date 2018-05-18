from utils import *
pk = 59939434428728383513377921651556138253385018136634027976979857224071561791174
v = 1000 # gwei
secret = 123124214

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
    with open("proofs/commitment/secret.input","w") as input_file:
        input_file.write("\n".join(secret_input))
    call("../../../target/release/zokrates compute-witness -a {} {} < secret.input > tmp".format(
    commitment,
    value
    ),
    shell=True, cwd="proofs/commitment")
    call("../../../target/release/zokrates generate-proof > commitment.proof", shell=True, cwd="proofs/commitment")
    with open('proofs/commitment/commitment.proof', 'r') as proof_file:
        proof_raw = proof_file.read()

    proof = raw_to_proof(proof_raw)
    return proof
