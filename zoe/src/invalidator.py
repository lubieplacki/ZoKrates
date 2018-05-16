def bits(name, number):
    return (", ").join(["{}Bit{}".format(name, i) for i in range(number-1, -1, -1)])

def privateBits(name, number):
    return (", ").join(["private {}Bit{}".format(name, i) for i in range(number-1, -1, -1)])

print "import \"./bit_check_32.code\" as bitCheck32"
print "import \"./bit_check_256.code\" as bitCheck256"
print "import \"./sha256/sha256.code\" as sha256Compress"
print " "
print " "
print "def main(inputInvalidator, private inputPrivateKey, private inputId, {}, {}):".format(privateBits("inputPrivateKey", 256), privateBits("inputId", 32))
print "  1 == bitCheck256(inputPrivateKey, {})".format(bits("inputPrivateKey", 256))
print "  "
print "  1 == bitCheck32(inputId, {})".format(bits("inputId", 32))
print "  "
bits_to_fill = 512 - 256 - 32
print "  {} = sha256Compress({}, {}, {})".format(
    bits("hash", 256),
    bits("inputPrivateKey", 256),
    bits("inputId", 32),
    (", ").join(["0" for i in range(0, bits_to_fill)]))
print " "
print "  // Check if invalidator is correctly computed"
print "  hash = 0"
for i in range(255, -1, -1):
    print "  hash = hash * 2 + hashBit{}".format(i)
print "  hash == inputInvalidator"
print "  return 1"
