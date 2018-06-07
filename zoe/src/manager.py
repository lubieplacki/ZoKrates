contract_abi = json.loads("""[
{
    "name": "deposit",
    "constant": false,
    "inputs": [
        {"name": "a", "type": "uint256[2]"},
        {"name": "a_p", "type": "uint256[2]"},
        {"name": "b", "type": "uint256[2][2]"},
        {"name": "b_p", "type": "uint256[2]"},
        {"name": "c", "type": "uint256[2]"},
        {"name": "c_p", "type": "uint256[2]"},
        {"name": "h", "type": "uint256[2]"},
        {"name": "k", "type": "uint256[2]"},
        {"name": "commitment", "type": "uint"},
        {"name": "encrypted_msg", "type": "string"}
    ],
    "outputs": [{"name": "result", "type": "bool"}],
    "payable": true,
    "stateMutability": "payable",
    "type": "function"
},
{
    "name": "transaction",
    "constant": false,
    "inputs": [
        {"name": "a", "type": "uint256[2]"},
        {"name": "a_p", "type": "uint256[2]"},
        {"name": "b", "type": "uint256[2][2]"},
        {"name": "b_p", "type": "uint256[2]"},
        {"name": "c", "type": "uint256[2]"},
        {"name": "c_p", "type": "uint256[2]"},
        {"name": "h", "type": "uint256[2]"},
        {"name": "k", "type": "uint256[2]"},
        {"name": "invalidator", "type": "uint256"},
        {"name": "root", "type": "uint256"},
        {"name": "commitment_out", "type": "uint256"},
        {"name": "commitment_change", "type": "uint256"},
        {"name": "encrypted_msg", "type": "string"}
    ],
    "outputs": [{"name": "result", "type": "bool"}],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "function"
},
{
    "name": "withdraw",
    "constant": false,
    "inputs": [
        {"name": "a", "type": "uint256[2]"},
        {"name": "a_p", "type": "uint256[2]"},
        {"name": "b", "type": "uint256[2][2]"},
        {"name": "b_p", "type": "uint256[2]"},
        {"name": "c", "type": "uint256[2]"},
        {"name": "c_p", "type": "uint256[2]"},
        {"name": "h", "type": "uint256[2]"},
        {"name": "k", "type": "uint256[2]"},
        {"name": "invalidator", "type": "uint256"},
        {"name": "root", "type": "uint256"},
        {"name": "value_out", "type": "uint256"},
        {"name": "commitment_change", "type": "uint256"}
    ],
    "outputs": [{"name": "result", "type": "bool"}],
    "payable": false,
    "stateMutability": "nonpayable",
    "type": "function"
},
{
    "name": "TransactionEvent",
    "anonymous": false,
    "inputs": [{ "name": "encrypted_msg", "indexed": false, "type": "string"}],
    "type": "event"
},
{
    "name": "getCommitments",
    "inputs": [],
    "outputs": [{"name": "commitments", "type": "uint256[1048576]"}]
    "constant": true,
    "payable": false,
    "type": "function",
}
]')
""")
