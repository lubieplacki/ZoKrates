#source ~/virtualenvs/venv/bin/activate
from deploy_contracts import *
w3 = Web3(EthereumTesterProvider())
manager = deploy_manager(w3)

from utils import *
zero512 = [0 for x in range(0,512)]
zeroU = 0
manager.functions.getSha256_UInt(zeroU, zeroU).call()
bits_to_int(sha256(zero512))

from gen_public_key import *
seed = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
seed2 = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
secret_key, public_key, rsa_private_key, rsa_public_key = gen_keys(seed)
out_sk, out_pk, rsa_private_key_out, rsa_public_key_out = gen_keys(seed2)

from zoe import *
w3.eth.getBalance(w3.eth.accounts[0])
w3.eth.getBalance(manager.address)
deposit(w3, manager, 4, public_key, rsa_public_key)
w3.eth.getBalance(w3.eth.accounts[0])
w3.eth.getBalance(manager.address)
deposit(w3, manager, 105, public_key, rsa_public_key)
w3.eth.getBalance(w3.eth.accounts[0])
w3.eth.getBalance(manager.address)

manager.functions.getCommitmentsTree().call()
commitments = available_commitments(manager, secret_key, public_key, rsa_private_key)

in_secret = commitments[1]['secret']
in_value = commitments[1]['value']
in_commitment = commitments[1]['commitment']
rsa_public_key_change = rsa_public_key
public_key_change = public_key
out_value = 5
result = transaction(w3, manager, public_key, secret_key, 5, out_pk, rsa_public_key_out, rsa_public_key, in_value, in_commitment, in_secret)
available_commitments(manager, secret_key, public_key, rsa_private_key)

w3.eth.getBalance(w3.eth.accounts[0])
w3.eth.getBalance(manager.address)

transaction(w3, manager, public_key, secret_key, 1, out_pk, rsa_public_key_out, rsa_public_key, commitments[0]['value'], commitments[0]['commitment'], commitments[0]['secret'])
available_commitments(manager, secret_key, public_key, rsa_private_key)

w3.eth.getBalance(w3.eth.accounts[0])
w3.eth.getBalance(manager.address)


commitsSecondGuy = available_commitments(manager, out_sk, out_pk, rsa_private_key_out)
w3.eth.getBalance(w3.eth.accounts[1])
w3.eth.defaultAccount = w3.eth.accounts[1]
withdraw(w3, manager, out_pk, out_sk, 3, 5, commitsSecondGuy[0]['commitment'], commitsSecondGuy[0]['secret'], rsa_private_key_out)
w3.eth.getBalance(w3.eth.accounts[1])
w3.eth.getBalance(manager.address)
available_commitments(manager, out_sk, out_pk, rsa_private_key_out)
