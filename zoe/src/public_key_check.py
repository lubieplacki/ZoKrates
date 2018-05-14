print "import \"./bit_convert_32.code\" as bit_convert_32"
print "import \"./sha256/sha256.code\" as sha256_compress"
def bits(name, number):
    return (", ").join(["{}_bit{}".format(name, i) for i in range(number-1, -1, -1)])

print "def main(input_public_key, private input_private_key):"
print "  {} = bit_convert_32(input_private_key)".format(bits("input_private_key", 32))
bits_to_fill = 512 - 32
print "  {} = sha256_compress({}, {})".format(bits("hash", 256), bits("input_private_key", 32), (", ").join(["0" for i in range(0, bits_to_fill)]))
print "  hash = 0"
for i in range(0, 32):
    print "  hash = 2 * hash + hash_bit{}".format(255 - i)
print "  hash == input_public_key"
print "  return 1"
