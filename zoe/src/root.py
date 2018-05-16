depth = input()
def bits(name, number):
    return (", ").join(["{}Bit{}".format(name, i) for i in range(number-1, -1, -1)])

def privateBits(name, number):
    return (", ").join(["private {}Bit{}".format(name, i) for i in range(number-1, -1, -1)])

print "import \"./bit_check_256.code\" as bitCheck256"
print "import \"./sha256/sha256.code\" as sha256Compress"

left_private_input_path = (", ").join(["private leftInputPath{}".format(i) for i in range(0, depth)])
left_input_path = (", ").join(["leftInputPath{}".format(i) for i in range(0, depth)])
left_private_input_path_bits = (", ").join([privateBits("leftInputPath{}".format(i), 256) for i in range(0, depth)])

right_private_input_path = (", ").join(["private rightInputPath{}".format(i) for i in range(0, depth)])
right_input_path = (", ").join(["rightInputPath{}".format(i) for i in range(0, depth)])
right_private_input_path_bits = (", ").join([privateBits("rightInputPath{}".format(i), 256) for i in range(0, depth)])


print "def main(root, private inputCommitment, {}, {}, {}, {}):".format(
    left_private_input_path,
    right_private_input_path,
    left_private_input_path_bits,
    right_private_input_path_bits
    )
print "  hash = inputCommitment"
for i in range(0, depth):
    print "  check = if hash == leftInputPath{} then leftInputPath{} else rightInputPath{} fi".format(i, i, i)
    print "  hash == check"
    print "  1 == bitCheck256(leftInputPath{}, {})".format(i, bits("leftInputPath{}".format(i), 256))
    print "  1 == bitCheck256(rightInputPath{}, {})".format(i, bits("rightInputPath{}".format(i), 256))
    print "  {} = sha256Compress({}, {})".format(
        bits("hash", 256),
        bits("leftInputPath{}".format(i), 256),
        bits("rightInputPath{}".format(i), 256)
    )
    print "  hash = 0"
    for i in range(255, -1, -1):
        print "  hash = hash * 2 + hashBit{}".format(i)

print "  hash == root"
print "  return 1"
