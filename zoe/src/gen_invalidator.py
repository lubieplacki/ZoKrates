from src.utils import *
from subprocess import call

def gen_invalidator_bits(private_key, secret):
    private_key_bits = int_to_bits(private_key, 256)
    secret_bits = int_to_bits(secret, 32)
    hash_bits = sha256(private_key_bits + secret_bits)
    return hash_bits

def gen_invalidator(private_key, secret):
    return bits_to_int(gen_invalidator_bits(private_key, secret))
