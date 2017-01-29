from templates import js, swig, java, swift


class FuncSpec(object):

    def __init__(self, arguments):
        self.arguments = arguments


F = FuncSpec

SHA256_LEN = 32
SHA512_LEN = 64
HASH160_LEN = 20
HMAC_SHA256_LEN = 32
HMAC_SHA512_LEN = 64
PBKDF2_HMAC_SHA256_LEN = 32
PBKDF2_HMAC_SHA512_LEN = 64


hash_func_spec = lambda out_size: F(
    ['const_bytes', ('out_bytes', out_size)]
)


hmac_func_spec = lambda out_size: F(
    ['const_bytes[key]', 'const_bytes[bytes]', ('out_bytes', out_size)]
)


pbkdf_func_spec = lambda out_size: F(
    ['const_bytes[pass]', 'const_bytes[salt]',
     'uint32_t[flags]', 'uint32_t[cost]',
     ('out_bytes', out_size)]
)


FUNCS = (
    ('wally_sha256', hash_func_spec(SHA256_LEN)),
    ('wally_sha256d', hash_func_spec(SHA256_LEN)),
    ('wally_sha512', hash_func_spec(SHA512_LEN)),
    ('wally_hash160', hash_func_spec(HASH160_LEN)),
    ('wally_hmac_sha256', hmac_func_spec(HMAC_SHA256_LEN)),
    ('wally_hmac_sha512', hmac_func_spec(HMAC_SHA512_LEN)),
    ('wally_pbkdf2_hmac_sha256', pbkdf_func_spec(PBKDF2_HMAC_SHA256_LEN)),
    ('wally_pbkdf2_hmac_sha512', pbkdf_func_spec(PBKDF2_HMAC_SHA512_LEN))
)


def main():
    with open('swig.i', 'w') as f:
        f.write(swig.generate(FUNCS))

    with open('wally.js', 'w') as f:
        f.write(js.generate(FUNCS))

    with open('WallyCordova.java', 'w') as f:
        f.write(java.generate(FUNCS))


if __name__ == '__main__':
    main()
