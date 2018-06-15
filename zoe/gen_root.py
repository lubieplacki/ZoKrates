# tutaj generujemy ścieżki od commita do roota na podstawie merkletree
from utils import *

def gen_root(commitments, in_commitment, TREE_DEPTH):
    x = 0
    for i in range(0, len(commitments)):
        x = i
        if commitments[i] == in_commitment:
            break
    to_add = 1
    tree = [0]
    for i in range(0, TREE_DEPTH):
        for j in range(0, to_add):
            if i != TREE_DEPTH - 1 or j >= len(commitments):
                tree.append(0)
            else:
                tree.append(commitments[j])
        to_add = to_add * 2
    start = to_add // 2
    print(tree)
    print(len(tree))
    print(start)
    start = len(tree) - start
    for i in range(start, 0, -1):
        tree[i] = bits_to_int(sha256((int_to_bits(tree[i*2], 256)).extend(int_to_bits(tree[i*2 + 1], 256))))
    left_path = []
    right_path = []
    i = (start + x) / 2
    while i > 0:
        left_path.append(tree[i * 2])
        right_path.append(tree[i * 2 + 1])
        i = i / 2
    return (tree[1], left_path, right_path)
