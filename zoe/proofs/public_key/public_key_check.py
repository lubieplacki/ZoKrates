print "import \"./bit_convert_32.code\" as bitConvert32"
print "import \"./sha256/sha256.code\" as sha256Compress"
def bits(name, number):
    return (", ").join(["{}Bit{}".format(name, i) for i in range(number-1, -1, -1)])

print "def main(inputPublicKey, private inputPrivateKey):"
print "  {} = bitConvert32(inputPrivateKey)".format(bits("inputPrivateKey", 32))
bits_to_fill = 512 - 32
print "  {} = sha256Compress({}, {})".format(
    bits("hash", 256),
    bits("inputPrivateKey", 32),
    (", ").join(["0" for i in range(0, bits_to_fill)])
    )
print "  hash = 0"
for i in range(0, 32):
    print "  hash = 2 * hash + hashBit{}".format(255 - i)
print "  hash == inputPublicKey"
print "  return 1"
