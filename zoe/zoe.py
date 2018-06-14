import random
from gen_commitment import *
from gen_invalidator import *
from gen_transaction import *
from gen_withdraw import *
from gen_root import *
from web3.contract import ConciseContract
from web3 import Web3, HTTPProvider
import json
from solc import compile_source, compile_files, link_code
import ast

maxInt = 2^32
contract_address = 0 #0x000

def init_manager():
    compiled = compile_files(["./src/Manager.sol"])
    contract_interface = compiled['<stdin>:Manager']
    web3 = Web3(TestRPCProvider())
    manager = web3.eth.contract(
        contract_address,
        abi=contract_interface['abi'],
        ContractFactoryClass=ConciseContract,
    )
    return manager


tree_depth = 21
def random_secret():
    return random.randomint(0, maxInt)
####
# register
## generate public_key
## *send* public_key to contract
## *get* verification keys
## save keys
def register(manager, public_key, rsa_public_key):
    manager.register(public_key, rsa_public_key, transact= {
        "from": web3.eth.accounts[0],
        "gas": 100000,
        "gasPrice":10**10,
    })
    ## *send* public_key to contract
    ## *get* verification keys
    ## save keys
def encrypt(msg, rsa_public_key):
    return rsa_public_key.encrypt(msg.encode("utf-8"), 32)[0]

def decrypt(msg, rsa_private_key):
    return rsa_private_key.decrypt(msg).decode("utf-8")

def encrypt_msg(public_key, secret, value, rsa_key_str):
    rsa_key = RSA.importKey(rsa_key_str)
    return encrypt("{'pk':{}, 'secret':{}, 'value':{}}".format(
        public_key,
        secret,
        value),
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
    proof = gen_commitment_proof(commitment, public_key, secret, value)
    print("Encrypting message...")

    encrypted_msg = encrypt_msg(public_key, secret, value, rsa_public_key)

    print("Depositing the funds")
    result = manager.deposit(
        proof['A'],
        proof['A_p'],
        proof['B'],
        proof["B_p"],
        proof["C"],
        proof["C_p"],
        proof["H"],
        proof["K"],
        commitment,
        encrypted_msg,
        transact= {
            "value": value,
            "from": web3.eth.accounts[0],
            "gas":2 * 10**6,
            "gasPrice":10**10,
        },
    )
    print("Finished.")
    print(result)
    ## *encode* public_key,value,secret
    ## *send* commitment, value, commitment_proof, encrypted message to contract
    ## print result

def get_commitments(manager):
    return manager.getCommitments()
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

def transaction(manager, public_key, secret_key, out_value, out_pk, rsa_public_key_out, rsa_public_key_change, in_value, in_commitment, in_secret):
    in_invalidator = gen_invalidator(secret_key, in_secret)

    list_of_commitments = get_commitments()
    (root, left_path, right_path) = gen_root(list_of_commitments, in_commitment, tree_depth)

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
    encrypted_msg_out = encrypt_msg(out_pk, out_secret, out_value, rsa_public_key_out)

    print("Encrypting 2nd message...")
    encrypted_msg_change = encrypt_msg(public_key, change_secret, change_value, rsa_public_key_change)

    print("Transfering the funds...")
    result = manager.transaction(
        proof['A'],
        proof['A_p'],
        proof['B'],
        proof["B_p"],
        proof["C"],
        proof["C_p"],
        proof["H"],
        proof["K"],
        invalidator,
        root,
        commitment_out,
        commitment_change,
        encrypted_msg_out,
        encrypted_msg_change,
        transact= {
            "from": web3.eth.accounts[0],
            "gas":2 * 10**6,
            "gasPrice":10**10,
        },
    )
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
def withdraw(manager, public_key, secret_key, out_value, in_value, in_commitment, in_secret, rsa_public_key_change):
    in_invalidator = gen_invalidator(secret_key, in_secret)

    list_of_commitments = get_commitments()
    (root, left_path, right_path) = gen_root(list_of_commitments, in_commitment, tree_depth)

    change_value = in_value - out_value
    change_secret = random_secret()
    change_commitment = gen_commitment(public_key, change_secret, change_value)

    proof = gen_withdraw_proof(in_invalidator, root, change_commitment,
        in_value, in_secret, secret_key, public_key,
        in_commitment, left_path, right_path,
        change_value, change_secret, public_key,
        out_value)

    print("Encrypting message...")
    encrypted_msg_change = encrypt_msg(public_key, change_secret, change_value, rsa_public_key_change)

    print("Transfering the funds...")
    result = manager.transaction(
        proof['A'],
        proof['A_p'],
        proof['B'],
        proof["B_p"],
        proof["C"],
        proof["C_p"],
        proof["H"],
        proof["K"],
        invalidator,
        root,
        value_out,
        commitment_change,
        encrypted_msg_change,
        transact= {
            "from": web3.eth.accounts[0],
            "gas":2 * 10**6,
            "gasPrice":10**10,
        },
    )
    print("Finished.")
    print(result)

def available_commitments(manager, secret_key, public_key, rsa_private_key):
    results = manager.events.TransactionEvent.createFilter({}, { fromBlock: 0, toBlock: 'latest' }).get_all_entries()
    print(results)
    commitments = []
    for result in results:
        encrypted_msg = results['encrypted_msg']
        decrypted = decrypt(encrypted_msg, rsa_private_key)
        try:
            decryptedObject = ast.literal_eval(decrypted)
            if (decryptedObject['pk'] == public_key):
                invalidator = gen_invalidator(secret_key, decryptedObject['secret'])
                if (manager.checkInvalidator(invalidator) == false):
                    commitments.append(decryptedObject)
        except Exception as e:
            pass
    print(commitments)
    return commitments

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
