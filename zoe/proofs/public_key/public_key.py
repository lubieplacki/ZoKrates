def bits(name, number):
    return (", ").join(["{}Bit{}".format(name, i) for i in range(number-1, -1, -1)])

def privateBits(name, number):
    return (", ").join(["private {}Bit{}".format(name, i) for i in range(number-1, -1, -1)])

print "import \"./../utils/bit_check_32.code\" as bitCheck32"
print "import \"./../utils/bit_check_256.code\" as bitCheck256"

print "def main(inputPublicKey, private inputPrivateKey, {}):".format(privateBits("inputPrivateKey", 256))
print "  1 == bitCheck256(inputPrivateKey, {})".format(bits("inputPrivateKey", 256))
bits_to_fill = 512 - 256
print "  {} = sha256libsnark({}, {})".format(
    bits("hash", 256),
    bits("inputPrivateKey", 256),
    (", ").join(["0" for i in range(0, bits_to_fill)])
    )
print "  1 == bitCheck256(inputPublicKey, {})".format(bits("hash", 256))
print "  return 1"
