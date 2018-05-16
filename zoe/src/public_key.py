def bits(name, number):
    return (", ").join(["{}Bit{}".format(name, i) for i in range(number-1, -1, -1)])

def privateBits(name, number):
    return (", ").join(["private {}Bit{}".format(name, i) for i in range(number-1, -1, -1)])

print "import \"./bit_check_32.code\" as bitCheck32"
print "import \"./bit_check_256.code\" as bitCheck256"
print "import \"./sha256/sha256.code\" as sha256Compress"

print "def main(inputPublicKey, private inputPrivateKey, {}):".format(privateBits("inputPrivateKey", 256))
print "  1 == bitCheck256(inputPrivateKey, {})".format(bits("inputPrivateKey", 256))
bits_to_fill = 512 - 256
print "  {} = sha256Compress({}, {})".format(
    bits("hash", 256),
    bits("inputPrivateKey", 256),
    (", ").join(["0" for i in range(0, bits_to_fill)])
    )
print "  hash = 0"
for i in range(255, -1, -1):
    print "  hash = hash * 2 + hashBit{}".format(i)
print "  hash == inputPublicKey"
print "  return 1"
