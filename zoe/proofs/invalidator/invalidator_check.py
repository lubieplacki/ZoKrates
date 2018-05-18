print "import \"./bit_convert_32.code\" as bitConvert32"
print "import \"./sha256/sha256.code\" as sha256Compress"
print " "
def bits(name, number):
    return (", ").join(["{}Bit{}".format(name, i) for i in range(number-1, -1, -1)])
print " "
print "def main(inputInvalidator, private inputPrivateKey, private inputId):"
print "  {} = bitConvert32({})".format(bits("inputPrivateKey", 32), "inputPrivateKey")
print "  "
print "  {} = bitConvert32({})".format(bits("inputId", 32), "inputId")
print "  "
bits_to_fill = 512 - 32 - 32
print "  {} = sha256Compress({}, {}, {})".format(
    bits("hash", 256),
    bits("inputPrivateKey", 32),
    bits("inputId", 32),
    (", ").join(["0" for i in range(0, bits_to_fill)]))
print " "
print "  // Check if invalidator is correctly computed"
print "  hash = 0"
for i in range(255, -1, -1):
    print "  hash = hash * 2 + hashBit{}".format(i)
print "  hash == inputInvalidator"
print "  return 1"
