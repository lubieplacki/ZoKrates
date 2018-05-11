depth = input()
print "import './bit_convert_256.code' as bit_convert_256"
print "import './sha256_compress.code' as sha256_compress"
def bits(name, number):
    return (", ").join(["{}_bit{}".format(name, i) for i in range(number-1, -1, -1)])

left_private_input_path = (", ").join(["private left_input_path_{}".format(i) for i in range(0, depth)])
left_input_path = (", ").join(["left_input_path_{}".format(i) for i in range(0, depth)])
right_private_input_path = (", ").join(["private right_input_path_{}".format(i) for i in range(0, depth)])
right_input_path = (", ").join(["right_input_path_{}".format(i) for i in range(0, depth)])

print "def main(root, private input_commitment, {}, {}):".format(left_private_input_path, right_private_input_path)
print "  hash = input_commitment"
for i in range(0, depth):
    print "  check = if hash == left_input_path_{} then left_input_path_{} else right_input_path_{} fi".format(i, i, i)
    print "  hash == check"
    print "  {} = bit_convert_256(left_input_path_{})".format(bits("left_input_path_{}".format(i), 256), i)
    print "  {} = bit_convert_256(right_input_path_{})".format(bits("right_input_path_{}".format(i), 256), i)
    print "  {} = sha256_compress({}, {})".format(
        bits("hash", 256),
        bits("left_input_path_{}".format(i), 256),
        bits("right_input_path_{}".format(i), 256)
    )
    print "  hash = 0"
    for i in range(255, -1, -1):
        print "  hash = hash * 2 + hash_bit{}".format(i)

print "  hash == root"
print "  return 1"
