#TODO figure out privacy
print "import \"./commitment_check.code\" as commitmentCheck"
print "import \"./invalidator_check.code\" as invalidatorCheck"
print "import \"./public_key_check.code\" as publicKeyCheck"
depth = input()
print "import \"./root_check{}.code\" as rootCheck".format(depth)
print " "
print "// i256 inputInvalidator, i256 root, i32 outValue, i256 changeCommitment"

left_private_input_path = (", ").join(["private leftInputPath{}".format(i) for i in range(0, depth)])
left_input_path = (", ").join(["leftInputPath{}".format(i) for i in range(0, depth)])
right_private_input_path = (", ").join(["private rightInputPath{}".format(i) for i in range(0, depth)])
right_input_path = (", ").join(["rightInputPath{}".format(i) for i in range(0, depth)])

print "def main(inputInvalidator, root, outValue, changeCommitment, \
    private inputValue, private inputId, private inputPrivateKey, private inputPublicKey, \
    private inputCommitment, {}, {}, private changeValue, private changeId, private changePublicKey):" \
    .format(left_private_input_path, right_private_input_path)
#TODO everything has to be private
print "  \\\\Check input coin is correct"
print "  commitment_check(inputValue, inputCommitment, inputId, inputPublicKey) == 1"
print "  public_key_check(inputPublicKey, inputPrivateKey) == 1"
print "  invalidator_check(inputInvalidator, inputPrivateKey, inputId) == 1"
print "  root_check(root, inputCommitment, {}, {}) == 1".format(left_input_path, right_input_path)
print "  "
print "  \\\\Check if output is correct"
print "  inputValue == outValue + changeValue"
print "  "
#TODO change_value has to be private
print "  \\\\Check if change commitment is correct"
print "  commitmentCheck(changeValue, changeCommitment, changeId, changePublicKey) == 1"
print "  return 1"
