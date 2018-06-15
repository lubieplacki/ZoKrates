from web3.contract import ConciseContract
from web3 import Web3, HTTPProvider, EthereumTesterProvider
import json
from solc import compile_source, compile_files, link_code
import ast

def compile_verifier(w3, path):
    compiled = compile_files([path])
    contract_interface = compiled[path + ":Verifier"]
    w3.eth.defaultAccount = w3.eth.accounts[0]
    verifier = w3.eth.contract(
        abi=contract_interface['abi'],
        bytecode=contract_interface['bin']
    )
    tx_hash = verifier.constructor().transact()
    tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
    verifier = w3.eth.contract(
        address=tx_receipt.contractAddress,
        abi=contract_interface['abi'],
    )
    return verifier

def deploy_all(w3):
    #w3 = Web3(EthereumTesterProvider())
    commitment = compile_verifier(w3, "./proofs/commitment/verifier.sol")
    transaction = compile_verifier(w3, "./proofs/transaction/verifier.sol")
    withdraw = compile_verifier(w3, "./proofs/withdraw/verifier.sol")

    compiled = compile_files(["./src/Manager.sol"])
    contract_interface = compiled['./src/Manager.sol:Manager']
    w3.eth.defaultAccount = w3.eth.accounts[0]
    manager = w3.eth.contract(
        abi=contract_interface['abi'],
        bytecode=contract_interface['bin']
    )
    tx_hash = manager.constructor(commitment.address, transaction.address, withdraw.address).transact()
    tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
    manager = w3.eth.contract(
        address=tx_receipt.contractAddress,
        abi=contract_interface['abi'],
    )
    return manager, commitment, transaction, withdraw
