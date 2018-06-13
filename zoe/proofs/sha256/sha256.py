input_par = []
for x in range(511,-1,-1):
    input_par.append("i" + str(x))
input_par = ", ".join(input_par)
output_par = []
for x in range(255,-1,-1):
    input_par.append("o" + str(x))
output_par = ", ".join(output_par)
print "def main({}):".format(input_par)
print "  {} = sha256libsnark({})".format(output_par, input_par)
print "  return {}".format(output_par)
