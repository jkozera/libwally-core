#ifndef LIBWALLY_BASE58_H
#define LIBWALLY_BASE58_H

/**
 * Calculate the base58 checksum of a block of binary data.
 *
 * @bytes_in: Binary data to calculate the checksum for.
 * @len: The length of @bytes_in in bytes.
 */
uint32_t base58_get_checksum(
    const unsigned char *bytes_in,
    size_t len);

int wally_base58_get_length(const char *str_in, size_t *written);
int wally_base58_from_bytes(const unsigned char *bytes_in, size_t len_in,
                            uint32_t flags, char **output);
int wally_base58_to_bytes(const char *str_in, uint32_t flags,
                          unsigned char *bytes_out, size_t len,
                          size_t *written);


#endif /* LIBWALLY_BASE58_H */
