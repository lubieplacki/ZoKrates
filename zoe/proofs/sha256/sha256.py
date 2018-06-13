input_par = []
for x in range(511,-1,-1):
    input_par.append("i" + str(x))
input_par = ", ".join(input_par)
print "def main({}):".format(input_par)
print "  return sha256libsnark({})".format(input_par)
