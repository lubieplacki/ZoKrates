print "import \"./bit_convert_32.code\" as bit_convert_32"
print "import \"./sha256/sha256.code\" as sha256_compress"
print " "
def bits(name, number):
    return (", ").join(["{}_bit{}".format(name, i) for i in range(number-1, -1, -1)])
print " "
print "def main(input_invalidator, private input_private_key, private input_id):"
print "  {} = bit_convert_32({})".format(bits("input_private_key", 32), "input_private_key")
print "  "
print "  {} = bit_convert_32({})".format(bits("input_id", 32), "input_id")
print "  "
bits_to_fill = 512 - 32 - 32
print "  {} = sha256_compress({}, {}, {})".format(
    bits("hash", 256),
    bits("input_private_key", 32),
    bits("input_id", 32),
    (", ").join(["0" for i in range(0, bits_to_fill)]))
print " "
print "  \\\\ Check if invalidator is correctly computed"
print "  hash = 0"
for i in range(255, -1, -1):
    print "  hash = hash * 2 + hash_bit{}".format(i)
print "  hash == input_invalidator"
print "  return 1"
