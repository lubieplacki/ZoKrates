from subprocess import call

def bits_to_int(bits):
    res = 0
    for i in range(0, len(bits)):
        res = res * 2 + bits[len(bits) - 1 - i]
    return res

def sha256(params):
    if len(params) < 512:
        params.extend([0 for i in range(0, 512 - len(params))])
    params_strings = []
    for x in params:
        params_strings.append(str(x))
    params = " ".join(params_strings)
    call("../../../target/release/zokrates compute-witness -a {} > tmp".format(params), shell=True, cwd="proofs/sha256")

    witness = {}
    with open('proofs/sha256/witness', 'r') as witness_file:
        witness_output = (witness_file.read()).split()
        for i in range(0, len(witness_output), 2):
            witness[witness_output[i]] = witness_output[i+1]

    bits = []
    for i in range(255, -1, -1):
        bits.append(int(witness["~out_{}".format(i)]))
    return bits

def string_to_bits(string, length):
    string = string[0:length]
    bits = []
    for i in range(0, length):
        x = 0
        if i < len(string):
            x = ord(string[i])
        for j in range(0, 8):
            bits.append(x % 2)
            x = x // 2
    return bits

def int_to_bits(x, num_bits):
    bits = []
    for i in range(0, num_bits):
        bits.append(x % 2)
        x = x // 2
    return bits[::-1]

import ast
def raw_to_proof(proof_raw):
    proof_raw = proof_raw.splitlines()
    proof = {}
    start = False
    x = 0
    for line in proof_raw:
        if (start and x < 8):
            x = x + 1
            line = line.split(" = ")
            proof[line[0]] = ast.literal_eval("[{}]".format(line[1][16: -2]))
        if (start == False and line.find("Proof:") != -1):
            start = True

    return proof
