from utils import *
from subprocess import call

def gen_transaction_proof(input_invalidator, root, out_commitment, change_commitment,
    input_value, input_id, input_private_key, input_public_key,
    input_commitment, left_path, right_path,
    change_value, change_id, change_public_key,
    out_value, out_id, out_public_key):
    input_value_bits = int_to_bits(input_value, 32)
    input_id_bits = int_to_bits(input_id, 32)
    input_private_key_bits = int_to_bits(input_private_key, 256)
    input_public_key_bits = int_to_bits(input_public_key, 256)
    left_path_bits = []
    for path in left_path:
        left_path_bits.extend(int_to_bits(path, 256))
    right_path_bits = []
    for path in right_path:
        right_path_bits.extend(int_to_bits(path, 256))
    change_value_bits = int_to_bits(change_value, 32)
    change_id_bits = int_to_bits(change_id, 32)
    change_public_key_bits = int_to_bits(change_public_key, 256)
    out_value_bits = int_to_bits(out_value, 32)
    out_id_bits = int_to_bits(out_id, 32)
    out_public_key_bits = int_to_bits(out_public_key, 256)


    secret_input = [input_value, input_id, input_private_key, input_public_key,
    input_commitment] + left_path + right_path + [change_value, change_id, change_public_key,
    out_value, out_id, out_public_key] + input_value_bits + input_id_bits + input_private_key_bits + \
    input_public_key_bits + left_path_bits + right_path_bits + change_value_bits + \
    change_id_bits + change_public_key_bits + out_value_bits + out_id_bits + out_public_key_bits
    secret_input = " ".join([str(x) for x in secret_input])
    print("Computing the witness...")
    call("../../../target/release/zokrates compute-witness -a {} {} {} {} {} > tmp".format(
    input_invalidator, root, out_commitment, change_commitment, secret_input
    ),
    shell=True, cwd="proofs/transaction")
    print("Computing the proof...")
    call("../../../target/release/zokrates generate-proof > transaction.proof", shell=True, cwd="proofs/transaction")
    with open('proofs/transaction/transaction.proof', 'r') as proof_file:
        proof_raw = proof_file.read()

    proof = raw_to_proof(proof_raw)
    return proof
