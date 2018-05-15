
def bits(name, number):
    return (", ").join(["{}Bit{}".format(name, i) for i in range(number-1, -1, -1)])

def privateBits(name, number):
    return (", ").join(["private {}Bit{}".format(name, i) for i in range(number-1, -1, -1)])

bits_to_fill = 512 - 32 - 32 - 32
print "import \"./bit_check_32.code\" as bitCheck32"
print "import \"./sha256/sha256.code\" as sha256Compress"
print "// i32 value, i256 commitment, i32 id, i32 publicKey"
print "def main(commitment, value, private id, private publicKey, {}, {}, {}, {}):".format(privateBits("value", 32), privateBits("id", 32), privateBits("publicKey", 32), privateBits("random", 512))
print "  // Convert to bits for hash function"
print "  1 == bitCheck32(value, {})".format(bits("value", 32))
print " "
print "  1 == bitCheck32(id, {})".format(bits("id", 32))
print " "
print "  1 == bitCheck32(publicKey, {})".format(bits("publicKey", 32))
print " "

print "  {} = sha256Compress({}, {}, {}, {})".format(
    bits("hash", 256),
    bits("value", 32),
    bits("id", 32),
    bits("publicKey", 32),
    bits("random", bits_to_fill)
    )
print " "

print "  // Check if commitment is correctly computed"
print "  hash = 0"
for i in range(255, -1, -1):
    print "  hash = hash * 2 + hashBit{}".format(i)
print "  hash == commitment"
print "  return 1"
