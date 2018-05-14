print "import \"./bit_convert_32.code\" as bit_convert_32"
print "import \"./sha256/sha256.code\" as sha256_compress"
print "\\\\ i32 value, i256 commitment, i32 id, i32 public_key"
#commitment_words = (", ").join(["commitment_word_{}".format(i) for i in range(7, -1, -1)])
#public_key_words = (", ").join(["private public_key_word_{}".format(i) for i in range(7, -1, -1)])
#print "def main(value, {}, private id, {}):".format(commitment_words, public_key_words)
#print "def main(value, {}, private id, private public_key):".format(commitment_words)
print "def main(value, commitment, private id, private public_key):"
def bits(name, number):
    return (", ").join(["{}_bit{}".format(name, i) for i in range(number-1, -1, -1)])
print "  \\\\ Convert to bits for hash function"
print "  {} = bit_convert_32({})".format(bits("value", 32), "value")
print " "
print "  {} = bit_convert_32({})".format(bits("id", 32), "id")
print " "
print "  {} = bit_convert_32({})".format(bits("public_key", 32), "public_key")
print " "
bits_to_fill = 512 - 32 - 32 - 32
print "  {} = sha256_compress({}, {}, {}, {})".format(
    bits("hash", 256),
    bits("value", 32),
    bits("id", 32),
    bits("public_key", 32),
    (", ").join(["0" for i in range(0, bits_to_fill)]))
print " "

print "  \\\\ Check if commitment is correctly computed"
print "  hash = 0"
for i in range(255, -1, -1):
    print "  hash = hash * 2 + hash_bit{}".format(i)
print "  hash == commitment"
print "  return 1"
