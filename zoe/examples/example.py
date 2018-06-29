#source ~/virtualenvs/venv/bin/activate
from src.deploy_contracts import *
w3 = Web3(EthereumTesterProvider())
manager = deploy_manager(w3)

from src.gen_public_key import *
sender_seed = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
receiver_seed = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
sender_secret_key, sender_public_key,
    sender_rsa_private_key, sender_rsa_public_key = gen_keys(sender_seed)

receiver_secret_key, receiver_public_key,
    receiver_rsa_private_key, receiver_rsa_public_key = gen_keys(receiver_seed)

from zoe import *
w3.eth.getBalance(w3.eth.accounts[0])
w3.eth.getBalance(manager.address)

deposit(w3, manager, 4, sender_public_key, sender_rsa_public_key)
w3.eth.getBalance(w3.eth.accounts[0])
w3.eth.getBalance(manager.address)

deposit(w3, manager, 105, sender_public_key, sender_rsa_public_key)
w3.eth.getBalance(w3.eth.accounts[0])
w3.eth.getBalance(manager.address)

commitments = available_commitments(manager, sender_secret_key, sender_public_key, sender_rsa_private_key)
commitments

input_secret = commitments[1]['s']
input_value = commitments[1]['v']
input_commitment = commitments[1]['commit']
input_commitment_id = commitments[1]['id']
out_value = 5

result = transaction(
    manager,
    sender_public_key,
    sender_secret_key,
    out_value,
    receiver_public_key,
    receiver_rsa_public_key,
    sender_rsa_public_key,
    input_value,
    input_commitment,
    input_secret,
    input_commitment_id
)

available_commitments(manager, sender_secret_key, sender_public_key, sender_rsa_private_key)

w3.eth.getBalance(w3.eth.accounts[0])
w3.eth.getBalance(manager.address)

transaction(
    manager,
    sender_public_key,
    sender_secret_key,
    1,
    receiver_public_key,
    receiver_rsa_public_key,
    sender_rsa_public_key,
    commitments[0]['v'],
    commitments[0]['commit'],
    commitments[0]['s'],
    commitments[0]['id']

)
available_commitments(manager, sender_secret_key, sender_public_key, sender_rsa_private_key)

w3.eth.getBalance(w3.eth.accounts[0])
w3.eth.getBalance(manager.address)

commitments_receiver = available_commitments(manager, receiver_secret_key, receiver_public_key, receiver_rsa_private_key)
commitments_receiver

w3.eth.getBalance(w3.eth.accounts[1])
w3.eth.defaultAccount = w3.eth.accounts[1]

input_secret = commitments[0]['s']
input_value = commitsSecondGuy[0]['v']
input_commitment = commitments[0]['commit']
out_value = 3

withdraw(
    manager,
    receiver_public_key,
    receiver_secret_key,
    receiver_rsa_public_key,
    out_value,
    commitments_receiver[0]['v'],
    commitments_receiver[0]['commit'],
    commitments_receiver[0]['s'],
    commitments_receiver[0]['id']
)


w3.eth.getBalance(w3.eth.accounts[1])
w3.eth.getBalance(manager.address)

available_commitments(manager, receiver_secret_key, receiver_public_key, receiver_rsa_public_key)
