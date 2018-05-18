from utils import *
pk = 59939434428728383513377921651556138253385018136634027976979857224071561791174
v = 1000 # gwei
secret = 123124214

def gen_commitment_bits(pk, secret, value):
    pk_bits = int_to_bits(pk, 256)
    value_bits = int_to_bits(value, 32)
    secret_bits = int_to_bits(secret, 32)
    hash_bits = sha256(pk_bits + value_bits + secret_bits)
    return hash_bits

def gen_commitment(pk, secret, value):
    return bits_to_int(gen_commitment_bits(pk, secret, value))

def gen_commitment_proof(commitment, value, secret, pk):
    pk_bits = int_to_bits(pk, 256)
    value_bits = int_to_bits(value, 32)
    secret_bits = int_to_bits(secret, 32)
    secret_input = [secret] + [pk] + value_bits + secret_bits + pk_bits
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
