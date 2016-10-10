#include <include/wally_core.h>
#include <include/wally_crypto.h>
#include "internal.h"
#include "secp256k1/include/secp256k1_schnorr.h"
#include "ccan/ccan/build_assert/build_assert.h"
#include <stdbool.h>

#define EC_FLAGS_TYPES (EC_FLAG_ECDSA | EC_FLAG_SCHNORR)
#define EC_FLAGS_ALL (EC_FLAG_ECDSA | EC_FLAG_SCHNORR)

/* Check assumptions we expect to hold true */
static void assert_assumptions(void)
{
    BUILD_ASSERT(sizeof(secp256k1_ecdsa_signature) == EC_COMPACT_SIGNATURE_LEN);
}

static bool is_valid_ec_type(uint32_t flags)
{
    return ((flags & EC_FLAGS_TYPES) == EC_FLAG_ECDSA) ||
           ((flags & EC_FLAGS_TYPES) == EC_FLAG_SCHNORR);
}

int wally_ec_sign_compact(const unsigned char *priv_key, size_t priv_key_len,
                          const unsigned char *bytes_in, size_t len_in,
                          uint32_t flags,
                          unsigned char *bytes_out, size_t len)
{
    secp256k1_context *ctx;

    if (!priv_key || priv_key_len != EC_PRIVATE_KEY_LEN ||
        !bytes_in || len_in != EC_MESSAGE_HASH_LEN ||
        !is_valid_ec_type(flags) || flags & ~EC_FLAGS_ALL ||
        !bytes_out || len != EC_COMPACT_SIGNATURE_LEN)
        return WALLY_EINVAL;

    if (!(ctx = (secp256k1_context *)secp_ctx()))
        return WALLY_ENOMEM;

    if (flags & EC_FLAG_SCHNORR)
        return WALLY_EINVAL;     /* Not implemented yet */
    else {
        secp256k1_ecdsa_signature sig;

        /* FIXME: Allow overriding of nonce function for testing */
        if (!secp256k1_ecdsa_sign(ctx, &sig, bytes_in, priv_key, NULL, NULL)) {
            if (secp256k1_ec_seckey_verify(ctx, priv_key))
                return WALLY_ERROR; /* Nonce function failed */
            return WALLY_EINVAL; /* invalid priv_key */
        }

        /* Note this function is documented as never failing */
        secp256k1_ecdsa_signature_serialize_compact(ctx, bytes_out, &sig);
        clear(&sig, sizeof(sig));
    }

    return WALLY_OK;
}
