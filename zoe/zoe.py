import random
from src.gen_commitment import *
from src.gen_invalidator import *
from src.gen_transaction import *
from src.gen_withdraw import *
from web3.contract import ConciseContract
from web3 import Web3, HTTPProvider, EthereumTesterProvider
import json
from solc import compile_source, compile_files, link_code
import ast
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_OAEP

maxSecret = 2**32
contract_address = 0 #0x000
weiPerUnit = 100000000000000000

def init_manager(w3, manager_address):
    compiled = compile_files(["./contracts/Manager.sol"])
    contract_interface = compiled['./contracts/Manager.sol:Manager']

    w3.eth.defaultAccount = w3.eth.accounts[0]
    manager = w3.eth.contract(
        abi=contract_interface['abi'],
        address=manager_address
    )
    return manager

def random_secret():
    return random.randint(0, maxSecret)

####
# register
## *send* public_keys to contract
def register(manager, public_key, rsa_public_key):
    return manager.functions.register(public_key, rsa_public_key).transact()

def load_key(path):
    res = ""
    with open(path,"r") as key_file:
        res = key_file.read()
    return res

def encrypt(msg, rsa_key):
    if (isinstance(rsa_key, str)):
        rsa_key = RSA.importKey(rsa_key)
    encryptor = PKCS1_OAEP.new(rsa_key)
    return encryptor.encrypt(bytes(msg,"utf-8"))

def decrypt(msg, rsa_key):
    if (isinstance(rsa_key, str)):
        rsa_key = RSA.importKey(rsa_key)
    decryptor = PKCS1_OAEP.new(rsa_key)
    return decryptor.decrypt(ast.literal_eval(str(msg))).decode("utf-8")

def encrypt_msg(commitment, id_in_tree, public_key, secret, value, rsa_key):
    return encrypt("{" + "\'commit\':{}, \'id\':{}, \'pk\':{}, \'s\':{}, \'v\':{}".format(
        commitment,
        id_in_tree,
        public_key,
        secret,
        value) + "}",
        rsa_key
    )
####
# deposit
## input value
## input public_key
## random secret
## generate commitment
## generate commitment proof
## *encode* public_key,value,secret
## *send* commitment, value, commitment_proof, encrypted message to contract
## contract verifies proof, adds commitment to the tree and saves value
def deposit(manager, value, public_key, rsa_public_key):
    secret = random_secret()
    print("Creating commitment...")
    commitment = gen_commitment(public_key, secret, value)
    print("Generating zksnark..")
    proof = gen_commitment_proof(commitment, value, secret, public_key)
    size = manager.functions.get_size().call()
    print("Encrypting message...")

    encrypted_msg = encrypt_msg(commitment, size, public_key, secret, value, rsa_public_key)

    print("Depositing the funds")

    result = manager.functions.deposit(
        proof['A'],
        proof['A_p'],
        proof['B'],
        proof["B_p"],
        proof["C"],
        proof["C_p"],
        proof["H"],
        proof["K"],
        commitment,
        str(encrypted_msg),
    ).transact({
        "value": value * weiPerUnit,
        #"from": w3.eth.accounts[0],
        "gas":3 * 10**6,
        "gasPrice":10**10,
    })
    print("Finished.")
    return result

#####
# transaction
## load pk, sk
## input out_value, out_pk
## input in_commitment, in_value, in_secret
## gen in_invalidator sk, in_secret
## *scan* list_of_commitment to contract
## gen root,left_path,right_path from list_of_commitments, in_commitment
## count change_value
## random change_secret
## gen change_commitment - to pk, change_value, change_secret
## random out_secret
## gen out_commitment - to out_pk, out_value, out_secret
## gen transaction_proof
## encode stuff
## *send* transaction_proof, input_invalidator, root, change_commitment, out_commitment
## contract checks root, invalidator, proof, adds commitments

def transaction(manager, public_key, secret_key, out_value, out_pk, rsa_public_key_out, rsa_public_key_change, in_value, in_commitment, in_secret, in_id_in_tree):
    in_invalidator = gen_invalidator(secret_key, in_secret)

    (root, left_path, right_path) = manager.functions.get_merkle_proof(in_id_in_tree).call()
    size = manager.functions.get_size().call()

    change_value = in_value - out_value
    change_secret = random_secret()
    change_commitment = gen_commitment(public_key, change_secret, change_value)

    out_secret = random_secret()
    out_commitment = gen_commitment(out_pk, out_secret, out_value)

    proof = gen_transaction_proof(in_invalidator, root, out_commitment, change_commitment,
        in_value, in_secret, secret_key, public_key,
        in_commitment, left_path, right_path,
        change_value, change_secret, public_key,
        out_value, out_secret, out_pk)

    print("Encrypting message...")
    encrypted_msg_out = encrypt_msg(out_commitment, size, out_pk, out_secret, out_value, rsa_public_key_out)

    print("Encrypting 2nd message...")
    encrypted_msg_change = encrypt_msg(change_commitment, size + 1, public_key, change_secret, change_value, rsa_public_key_change)

    print("Transfering the funds...")
    result = manager.functions.transaction(
        proof['A'],
        proof['A_p'],
        proof['B'],
        proof["B_p"],
        proof["C"],
        proof["C_p"],
        proof["H"],
        proof["K"],
        [in_invalidator,
        root,
        out_commitment,
        change_commitment],
        str(encrypted_msg_out),
        str(encrypted_msg_change),
    ).transact()
    print("Finished.")
    print(result)

#####
# withdraw
## load pk, sk
## input out_value
## input in_commitment, in_value, in_secret
## gen in_invalidator sk, in_secret
## *scan* list_of_commitment to contract
## gen root,left_path,right_path from list_of_commitments, in_commitment
## count change_value
## random change_secret
## gen change_commitment - to pk, change_value, change_secret
## gen withdraw_proof
## *send* withdraw_proof, input_invalidator, root, change_commitment, out_value
## contract checks root, invalidator, proof, adds commitment, send out_value to sender
def withdraw(manager, public_key, secret_key, rsa_public_key_change, out_value, in_value, in_commitment, in_secret, in_id_in_tree):
    in_invalidator = gen_invalidator(secret_key, in_secret)

    (root, left_path, right_path) = manager.functions.get_merkle_proof(in_id_in_tree).call()
    size = manager.functions.get_size().call()

    change_value = in_value - out_value
    change_secret = random_secret()
    change_commitment = gen_commitment(public_key, change_secret, change_value)

    proof = gen_withdraw_proof(in_invalidator, root, change_commitment,
        in_value, in_secret, secret_key, public_key,
        in_commitment, left_path, right_path,
        change_value, change_secret, public_key,
        out_value)

    print("Encrypting message...")
    encrypted_msg_change = encrypt_msg(change_commitment, size, public_key, change_secret, change_value, rsa_public_key_change)

    print("Transfering the funds...")
    result = manager.functions.withdraw(
        proof['A'],
        proof['A_p'],
        proof['B'],
        proof["B_p"],
        proof["C"],
        proof["C_p"],
        proof["H"],
        proof["K"],
        [in_invalidator,
        root,
        change_commitment,
        out_value * weiPerUnit],
        str(encrypted_msg_change),
    ).transact()
    print("Finished.")
    return result

def available_commitments(manager, secret_key, public_key, rsa_private_key):
    results = manager.events.TransactionEvent.createFilter(fromBlock= 0, toBlock= 'latest').get_all_entries()
    commitments = []
    for result in results:
        encrypted_msg = result['args']['encrypted_msg']
        try:
            decrypted = decrypt(encrypted_msg, rsa_private_key)
            decrypted_object = ast.literal_eval(decrypted)
            if (decrypted_object['pk'] == public_key):
                invalidator = gen_invalidator(secret_key, decrypted_object['s'])
                if (manager.functions.check_invalidator(invalidator).call() == False):
                    commitments.append(decrypted_object)
        except Exception as e:
            pass
    return commitments

def available_addresses(manager):
    results = manager.events.RegisterEvent.createFilter(fromBlock= 0, toBlock= 'latest').get_all_entries()
    res = []
    for result in results:
        r = result['args']
        res.append(r)
    return res
#####
# available_commitments
## *scan* invalidators
## *scan* transactions sent to contract
## check if after decoding a message public key is there
## generate invalidator
## check if invalidated
## save value and secret
## list available commitments
#####
#####
# consolidate - in future - adds up commitments
## load pk, sk
## 2 times:
### input in_commitment, in_value, in_secret
### gen in_invalidator sk, in_secret
### scan list_of_commitment to contract
### gen root,left_path,right_path from list_of_commitments, in_commitment
## random out_secret
## gen out_commitment - to pk, sum_values, out_secret
## gen consolidate_proof
## contract checks root, invalidators, proof, add commitment
