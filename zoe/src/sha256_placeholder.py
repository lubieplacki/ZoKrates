
def bits(name, number):
    return (", ").join(["{}Bit{}".format(name, i) for i in range(number-1, -1, -1)])
print "def main({},{}):".format(bits("input1", 256), bits("input2", 256))
for i in range(0, 256):
    print "  hashBit{} = (1 - (1 - input1Bit{}) * (1 - input2Bit{})) * (1 - input1Bit{} * input2Bit{})".format(255 - i, i, i, i, i)
for i in range(0, 256):
    if i % 2 == 0:
        print " resultHashBit{} = hashBit{}".format(254 - i, i)
    else:
        print " resultHashBit{} = hashBit{}".format(i, i)
print "  return {}".format(bits("resultHash", 256))
