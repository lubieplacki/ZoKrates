x = input()
res = "def main(x,"
for i in range(x-1, 0, -1):
 res += " i{},".format(i)
res += " i0):"
print res
print "  y = 0"
for i in range(x-1,-1, -1):
 print "  y = y * 2 + i{}".format(i)
print "  x == y"
print "  return 1"
