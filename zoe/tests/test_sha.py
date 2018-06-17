from deploy_contracts import *
w3 = Web3(EthereumTesterProvider())
m = deploy_manager(w3)
zero512 = [0 for x in range(0,512)]
zero64 = [0 for x in range(0,64)]
zeroU = 0
zero32 = [0 for x in range(0,32)]
zeroB = w3.toBytes(hexstr='0x0000000000000000000000000000000000000000000000000000000000000000')
m.functions.getCommitmentsTree().call()
m.functions.getSha256UInt(zero64).call()
m.functions.getSha256_8UInt(zero32, zero32).call()
m.functions.getSha256_UInt(zeroU, zeroU).call()
m.functions.getSha256_bytes_UInt(zeroB, zeroB).call()
from utils import *
sha256(zero512)
bits_to_int(sha256(zero512))
bits_to_int((sha256(zero512)[::-1]))


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
