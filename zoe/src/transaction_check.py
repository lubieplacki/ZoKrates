#TODO figure out privacy
print "import './commitment_check.code' as commitment_check"
print "import './invalidator_check.code' as invalidator_check"
print "import './public_key_check.code' as public_key_check"
depth = input()
print "import './root_check{}.code' as root_check".format(depth)
print " "
print "\\\\ i256 input_invalidator, i256 root, i32 out_value, i256 change_commitment"
left_private_input_path = (", ").join(["private left_input_path_{}".format(i) for i in range(0, depth)])
left_input_path = (", ").join(["left_input_path_{}".format(i) for i in range(0, depth)])
right_private_input_path = (", ").join(["private right_input_path_{}".format(i) for i in range(0, depth)])
right_input_path = (", ").join(["right_input_path_{}".format(i) for i in range(0, depth)])

print "def main(input_invalidator, root, out_commitment, change_commitment, \
    private input_value, private input_id, private input_private_key, private input_public_key, \
    private input_commitment, {}, {}, \
    private change_value, private change_id, private change_public_key, \
    private out_value, private out_id, private out_public_key\
    ):" \
    .format(left_private_input_path, right_private_input_path)
#TODO everything has to be private
print "  \\\\Check input coin is correct"
print "  commitment_check(input_value, input_commitment, input_id, input_public_key) == 1"
print "  public_key_check(input_public_key, input_private_key) == 1"
print "  invalidator_check(input_invalidator, input_private_key, input_id) == 1"
print "  root_check(root, input_commitment, {}, {}) == 1".format(left_input_path, right_input_path)
print "  "
print "  \\\\Check if output is correct"
print "  input_value == out_value + change_value"
print "  "
#TODO change_value has to be private
print "  \\\\Check if change commitment is correct"
print "  commitment_check(change_value, change_commitment, change_id, change_public_key) == 1"
print "  \\\\Check if out commitment is correct"
print "  commitment_check(out_value, out_commitment, out_id, out_public_key) == 1"
print "  return 1"
