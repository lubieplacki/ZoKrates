import random
from gen_commitment import *
from gen_invalidator import *
from gen_transaction import *
from gen_withdraw import *
from gen_root import *
maxInt = 2^32
contract_address = 0 #0x000
tree_depth = 21
def random_secret():
    return random.randomint(0, maxInt)
####
# register
## generate public_key
## *send* public_key to contract
## *get* verification keys
## save keys
def register():
    public_key = input("Please input your public key")
    ## *send* public_key to contract
    ## *get* verification keys
    ## save keys
####
# deposit
## input value
## input public_key
## random secret
## generate commitment
## generate commitment proof
## *encode* public_key,value,secret
## *send* commitment, value, commitment_proof, encoded message to contract
## contract verifies proof, adds commitment to the tree and saves value
def deposit():
    value = input("Please input deposit value")
    public_key = input("Please input your public key")
    secret = random_secret()
    commitment = gen_commitment(public_key, secret, value)
    proof = gen_commitment_proof(commitment, public_key, secret, value)
    ## *encode* public_key,value,secret
    ## *send* commitment, value, commitment_proof, encoded message to contract
    ## print result


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

def transaction():
    public_key = input("Please input your public key")
    secret_key = input("Please input your secret key")
    out_value = input("Please input the output value")
    out_pk = input("Please input the output public key")

    in_value = input("Please input the input value")
    in_commitment = input("Please input the input commitment")
    in_secret = input("Please input the input id")

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
    ## encode stuff
    ## *send* transaction_proof, input_invalidator, root, change_commitment, out_commitment

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
def withdraw():
    public_key = input("Please input your public key")
    secret_key = input("Please input your secret key")
    out_value = input("Please input the output value")

    in_value = input("Please input the input value")
    in_commitment = input("Please input the input commitment")
    in_secret = input("Please input the input id")

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
    ## *send* withdraw_proof, input_invalidator, root, change_commitment, out_value
    ## contract checks root, invalidator, proof, adds commitment, send out_value to sender

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
