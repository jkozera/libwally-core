//
//  aes.h
//  libwally-core-ios
//
//  Created by Muhammad Enamul Huq Sarkar on 31/01/2017.
//  Copyright © 2017 isidoro carlo ghezzi. All rights reserved.
//

#ifndef aes_h
#define aes_h

#define AES_BLOCK_LEN   16 /** Length of AES encrypted blocks */
#define AES_KEY_LEN_128 16 /** AES-128 Key length */
#define AES_KEY_LEN_192 24 /** AES-192 Key length */
#define AES_KEY_LEN_256 32 /** AES-256 Key length */
#define AES_FLAG_ENCRYPT  1 /** Encrypt */
#define AES_FLAG_DECRYPT  2 /** Decrypt */

#define ALL_OPS (AES_FLAG_ENCRYPT | AES_FLAG_DECRYPT)


int wally_aes(const unsigned char *key, size_t key_len,
              const unsigned char *bytes_in, size_t len_in,
              uint32_t flags,
              unsigned char *bytes_out, size_t len);

#endif /* aes_h */
