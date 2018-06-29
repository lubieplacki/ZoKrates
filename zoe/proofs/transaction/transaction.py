depth = input()
print "import \"./../commitment/commitment.code\" as commitmentCheck"
print "import \"./../invalidator/invalidator.code\" as invalidatorCheck"
print "import \"./../public_key/public_key.code\" as publicKeyCheck"
print "import \"./../root/root.code\" as rootCheck".format(depth)
print "import \"./../utils/natural.code\" as naturalCheck"
def bits(name, number):
    return (", ").join(["{}Bit{}".format(name, i) for i in range(number-1, -1, -1)])

def privateBits(name, number):
    return (", ").join(["private {}Bit{}".format(name, i) for i in range(number-1, -1, -1)])

print " "
print "// i256 inputInvalidator, i256 root, i32 outValue, i256 changeCommitment"

left_private_input_path = (", ").join(["private leftInputPath{}".format(i) for i in range(0, depth)])
left_input_path = (", ").join(["leftInputPath{}".format(i) for i in range(0, depth)])
left_private_input_path_bits = (", ").join([privateBits("leftInputPath{}".format(i), 256) for i in range(0, depth)])
left_input_path_bits = (", ").join([bits("leftInputPath{}".format(i), 256) for i in range(0, depth)])

right_private_input_path = (", ").join(["private rightInputPath{}".format(i) for i in range(0, depth)])
right_input_path = (", ").join(["rightInputPath{}".format(i) for i in range(0, depth)])
right_private_input_path_bits = (", ").join([privateBits("rightInputPath{}".format(i), 256) for i in range(0, depth)])
right_input_path_bits = (", ").join([bits("rightInputPath{}".format(i), 256) for i in range(0, depth)])

print "def main(inputInvalidator, root, outCommitment, changeCommitment, \
    private inputValue, private inputId, private inputPrivateKey, private inputPublicKey, \
    private inputCommitment, {}, {}, \
    private changeValue, private changeId, private changePublicKey, \
    private outValue, private outId, private outPublicKey, \
    {}, {}, {}, \
    {}, \
    {}, {}, \
    {}, {}, {}, \
    {}, {}, {} \
    ):".format(
    left_private_input_path, right_private_input_path,
    privateBits("inputValue", 32), privateBits("inputId", 32), privateBits("inputPrivateKey", 256),
    privateBits("inputPublicKey", 256),
    left_private_input_path_bits, right_private_input_path_bits,
    privateBits("changeValue", 32), privateBits("changeId", 32), privateBits("changePublicKey", 256),
    privateBits("outValue", 32), privateBits("outId", 32), privateBits("outPublicKey", 256)
    )

print "  // Check input coin is correct"
print "  1 == commitmentCheck(inputCommitment, inputValue, inputId, inputPublicKey, {}, {}, {})".format(bits("inputValue", 32), bits("inputId", 32), bits("inputPublicKey", 256))
print "  1 == publicKeyCheck(inputPublicKey, inputPrivateKey, {})".format(bits("inputPrivateKey", 256))
print "  1 == invalidatorCheck(inputInvalidator, inputPrivateKey, inputId, {}, {})".format(bits("inputPrivateKey", 256), bits("inputId", 32))
print "  1 == rootCheck(root, inputCommitment, {}, {}, {}, {})".format(left_input_path, right_input_path, left_input_path_bits, right_input_path_bits)
print "  "
print "  // Check if output is correct"
print "  inputValue == outValue + changeValue"
print "  1 == naturalCheck(changeValue)"
print "  1 == naturalCheck(outValue)"
print "  "
print "  // Check if change commitment is correct"
print "  1 == commitmentCheck(changeCommitment, changeValue, changeId, changePublicKey, {}, {}, {})".format(bits("changeValue", 32), bits("changeId", 32), bits("changePublicKey", 256))
print "  // Check if out commitment is correct"
print "  1 == commitmentCheck(outCommitment, outValue, outId, outPublicKey, {}, {}, {})".format(bits("outValue", 32), bits("outId", 32), bits("outPublicKey", 256))
print "  return 1"
