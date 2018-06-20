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
deposit(w3, manager, 4, public_key, rsa_public_key)
deposit(w3, manager, 105, public_key, rsa_public_key)

manager.functions.getCommitmentsTree().call()
commitments = available_commitments(manager, secret_key, public_key, rsa_private_key)

transaction(w3, manager, public_key, secret_key, 5, out_pk, rsa_public_key_out, rsa_public_key, commitments[1]['value'], commitments[1]['commitment'], commitments[1]['secret'])
available_commitments(manager, secret_key, public_key, rsa_private_key)

transaction(w3, manager, public_key, secret_key, 5, out_pk, rsa_public_key_out, rsa_public_key, commitments[1]['value'], commitments[1]['commitment'], commitments[1]['secret'])
available_commitments(manager, secret_key, public_key, rsa_private_key)

available_commitments(manager, out_sk, out_pk, rsa_private_key_out)
