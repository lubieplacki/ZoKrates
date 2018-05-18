filename = input()
with open(filename,'rb') as f:
    while True:
        line=f.readline()
        if not line: break
        print line.replace("_", "B")[:-1]
