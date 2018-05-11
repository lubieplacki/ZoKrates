x = input()
print "def main(x):"
print "  y1 = 2"
for i in range(2, x):
 print "  y{} = y{} * y1".format(i, i-1)

for i in range(x-1, 1, -1):
 print "  y = y{}".format(i)
 print "  i{} = if x < y then 0 else 1 fi".format(i)
 print "  x = if x < y then x else x-y fi"

print "  y = 2"
print "  i1 = if x < y then 0 else 1 fi"
print "  x = if x < y then x else x-y fi"
print "  i0 = x"

res = "  return "
for i in range(x-1, -1, -1):
  res += "i{},".format(i)
print res
