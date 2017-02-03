//
//  scrypt.h
//  libwally-core-ios
//
//  Created by Muhammad Enamul Huq Sarkar on 03/02/2017.
//  Copyright © 2017 isidoro carlo ghezzi. All rights reserved.
//

#ifndef scrypt_h
#define scrypt_h

int wally_scrypt(const unsigned char *pass, size_t pass_len,
                 const unsigned char *salt, size_t salt_len,
                 uint32_t cost, uint32_t block_size, uint32_t parallelism,
                 unsigned char *bytes_out, size_t len);

#endif /* scrypt_h */
