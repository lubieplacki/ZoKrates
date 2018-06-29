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
    commitment = compile_verifier(w3, "./contracts/deposit_verifier.sol")
    transaction = compile_verifier(w3, "./contracts/transaction_verifier.sol")
    withdraw = compile_verifier(w3, "./contracts/withdraw_verifier.sol")

    compiled = compile_files(["./contracts/Manager.sol"])
    contract_interface = compiled['./contracts/Manager.sol:Manager']
    w3.eth.defaultAccount = w3.eth.accounts[0]
    manager = w3.eth.contract(
        abi=contract_interface['abi'],
        bytecode=contract_interface['bin']
    )
    tx_hash = manager.constructor(commitment.address, transaction.address, withdraw.address).transact({"gas": 3140000})
    tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)
    manager = w3.eth.contract(
        address=tx_receipt.contractAddress,
        abi=contract_interface['abi'],
    )
    return manager, commitment, transaction, withdraw

def deploy_manager(w3):
    manager, _, _, _ = deploy_all(w3)
    return manager
