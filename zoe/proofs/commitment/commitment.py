
def bits(name, number):
    return (", ").join(["{}Bit{}".format(name, i) for i in range(number-1, -1, -1)])

def privateBits(name, number):
    return (", ").join(["private {}Bit{}".format(name, i) for i in range(number-1, -1, -1)])

bits_to_fill = 512 - 32 - 32 - 256
print "import \"./../utils/bit_check_32.code\" as bitCheck32"
print "import \"./../utils/bit_check_256.code\" as bitCheck256"
print "// i32 value, i256 commitment, i32 id, i32 publicKey"
print "def main(commitment, value, private id, private publicKey, {}, {}, {}):".format(
privateBits("value", 32),
privateBits("id", 32),
privateBits("publicKey", 256))
print "  // Convert to bits for hash function"
print "  1 == bitCheck32(value, {})".format(bits("value", 32))
print " "
print "  1 == bitCheck32(id, {})".format(bits("id", 32))
print " "
print "  1 == bitCheck256(publicKey, {})".format(bits("publicKey", 256))
print " "

print "  {} = sha256libsnark({}, {}, {}, {})".format(
    bits("hash", 256),
    bits("publicKey", 256),
    bits("value", 32),
    bits("id", 32),
    (", ").join(["0" for i in range(0, bits_to_fill)]))
print " "

print "  // Check if commitment is correctly computed"
print "  1 == bitCheck256(commitment, {})".format(bits("hash", 256))
print "  return 1"
