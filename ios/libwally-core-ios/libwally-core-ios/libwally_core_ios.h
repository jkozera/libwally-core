//
//  libwally_core_ios.h
//  libwally-core-ios
//
//  Created by isidoro carlo ghezzi on 11/8/16.
//  Copyright © 2016 isidoro carlo ghezzi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "wally_bip39.h"
#import "wally_bip38.h"
#import "wordlist.h"
#include "aes.h"
#include "mnemonic.h"
#include "scrypt.h"
#include "base58.h"





@interface libwally_core_ios : NSObject
+ (NSString *) staticTest;
- (NSString *) objectTest;

+ (int) pbkdf2:(const unsigned char *)pass pass_len: (size_t)pass_len salt_in_out: (unsigned char *)salt_in_out salt_len: (size_t) salt_len flags: (uint32_t) flags cost: (uint32_t) cost bytes_out: (unsigned char *)bytes_out len: (size_t) len type: (size_t) type;


+ (int) hmac:(const unsigned char *)key key_len: (size_t) key_len bytes_in:
(const unsigned char *)bytes_in len_in: (size_t) len_in bytes_out:
(unsigned char *)bytes_out len: (size_t) len;


//hex
+ (int) hex_encode_test:(const unsigned char *)bytes_in len_in: (size_t) len_in output: (char **)output;
+ (int) hex_decode:(const char *)hex bytes_out:
(unsigned char *)bytes_out len:(size_t) len written: (size_t *)written;



@end
