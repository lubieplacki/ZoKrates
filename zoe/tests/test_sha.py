from deploy_contracts import *
w3 = Web3(EthereumTesterProvider())
m = deploy_manager(w3)
zero512 = [0 for x in range(0,512)]
zeroU = 0
m.functions.getSha256_UInt(zeroU, zeroU).call()
from utils import *
sha256(zero512)
bits_to_int(sha256(zero512))
bits_to_int((sha256(zero512)[::-1]))
from gen_public_key import *
seed = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
gen_keys(seed)
secret_key, public_key, rsa_private_key, rsa_public_key = load_keys()
manager = m
value = 4
m.functions.getCommitmentsTree().call()
from zoe import *
deposit(w3, m, value, public_key, rsa_public_key)
m.functions.getCommitmentsTree().call()
deposit(w3, m, value+1, public_key, rsa_public_key)

testing = """
 function getSha256UInt(uint8[64] input) view public returns (uint hash) {
  return uint(sha256(input));
}
function getSha256(uint8[64] input) view public returns (bytes32 hash) {
  return sha256(input);
}
function getSha256_UInt(uint input1, uint input2) view public returns (uint hash) {
  return uint(sha256(input1, input2));
}
function getSha256_(uint input1, uint input2) view public returns (bytes32 hash) {
  return sha256(input1, input2);
}
function getSha256_8(uint8[32] input1, uint8[32] input2) view public returns (bytes32 hash) {
  return sha256(input1, input2);
}
function getSha256_8UInt(uint8[32] input1, uint8[32] input2) view public returns (uint hash) {
  return uint(sha256(input1, input2));
}
function getSha256_bytes_(bytes32 input, bytes32 input2) view public returns (bytes32 hash) {
  return sha256(input, input2);
}
function getSha256_bytes_UInt(bytes32 input, bytes32 input2) view public returns (uint hash) {
  return uint(sha256(input, input2));
}

  """
