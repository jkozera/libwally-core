//
//  LibwallyCoreUnitTest.m
//  libwally-core-ios-example
//
//  Created by isidoro carlo ghezzi on 11/10/16.
//  Copyright © 2016 isidoro carlo ghezzi. All rights reserved.
//

#import "LibwallyCoreUnitTest.h"
#import "libwally-core-ios/libwally_core_ios.h"

@interface NSString (NSStringHexToBytes)
-(NSData*) hexToBytes ;
@end



@implementation NSString (NSStringHexToBytes)
-(NSData*) hexToBytes {
	NSMutableData* data = [NSMutableData data];
	int idx;
	for (idx = 0; idx+2 <= self.length; idx+=2) {
		NSRange range = NSMakeRange(idx, 2);
		NSString* hexStr = [self substringWithRange:range];
		NSScanner* scanner = [NSScanner scannerWithString:hexStr];
		unsigned int intValue;
		[scanner scanHexInt:&intValue];
		[data appendBytes:&intValue length:1];
	}
	return data;
}
@end


@interface LibwallyCoreUnitTest ()
@property (weak, nonatomic) UITextView *fDebugTextView;
@property (strong, nonatomic) NSDictionary *fLanguagesDictionary;
@property (strong, nonatomic) NSDictionary *fVectorsDictionary;
@end

@implementation LibwallyCoreUnitTest

- (instancetype)initWithDebugView:(UITextView *) theDebugView {
	self = [self init];
	if(self) {
		self.fDebugTextView = theDebugView;
		self.fLanguagesDictionary = @{
			@"en": @"english",
			@"es": @"spanish",
			@"fr": @"french",
			@"it": @"italian",
			@"jp": @"japanese",
			@"zhs": @"chinese_simplified",
			@"zht": @"chinese_traditional"
		};
		
		NSFileManager * aFileManager = [NSFileManager defaultManager];
		NSString* filePath = [[NSBundle mainBundle] pathForResource:@"vectors"
															 ofType:@"json"];
		NSData * aData = [aFileManager contentsAtPath:filePath];
		NSError *error;
		self.fVectorsDictionary = [NSJSONSerialization JSONObjectWithData:aData options:NSJSONReadingAllowFragments error:&error];
		NSAssert (nil != self.fVectorsDictionary, @"nil != self.fVectorsDictionary");
	}
	return self;
}

-(NSArray *) get_languages{
	char * aLanguages = NULL;
	const int aBip39_get_languages = bip39_get_languages (&aLanguages);
	NSLog (@"aBip39_get_languages: %@, aLanguages: %s", @(aBip39_get_languages), aLanguages);
	NSString * aLanguagesString = [NSString stringWithUTF8String:aLanguages];
	wally_free_string (aLanguages);
	NSArray * aLanguagesArray = [aLanguagesString componentsSeparatedByString: @" "];
	return aLanguagesArray;
}

-(void) test_all_langs{
	NSArray * aLanguagesArray = [self get_languages];
	for (NSString * aLanguage in aLanguagesArray){
		NSAssert (nil != self.fLanguagesDictionary [aLanguage], @"nil != self.fLanguagesDictionary [aLanguage]");
	}
	NSAssert (self.fLanguagesDictionary.allKeys.count == aLanguagesArray.count, @"self.fLanguagesDictionary.allKeys.count == aLanguagesArray.count");
}

-(const struct words *) get_wordlist:(NSString *) theLang{
	const struct words * aWords = NULL;
	const char * aCKey = [theLang cStringUsingEncoding:NSUTF8StringEncoding];
	const int aBip39_get_wordlist = bip39_get_wordlist (aCKey, &aWords);
	NSAssert (WALLY_OK == aBip39_get_wordlist, @"WALLY_OK == aBip39_get_wordlist");
	return aWords;
}

-(NSArray *) test_load_word_list{
	NSMutableArray * aLogArray = [[NSMutableArray alloc] init];

	NSArray * aLanguagesArray = [self get_languages];
	
	for (NSString * aKey in aLanguagesArray){
		const struct words * aWords = [self get_wordlist:aKey];
		for (size_t i = 0; i < aWords->len && i < 3; ++i){
			NSString * aString = [NSString stringWithUTF8String:aWords->indices [i]];
			NSString * aLog = [NSString stringWithFormat:@"%@/%@ - %@ - %@;", @(i+1), @(aWords->len), aKey, aString];
			[aLogArray addObject:aLog];
		}
	}
	return aLogArray;
}

- (void) test_bip39_vectors{
	// ported from 'src/test/test_bip39.py'
	const struct words * aWordList = [self get_wordlist:nil];
	for (NSArray * aCase in self.fVectorsDictionary [@"english"]){
		NSLog (@"%@", aCase.description);
		NSString * aHexInputString = aCase [0];
		NSString  * aMenemonic = aCase [1];
		NSData * aBuf = [aHexInputString hexToBytes];
		char * aOutput = NULL;
		const void * aBufBytes = [aBuf bytes];
		const int aBip39_mnemonic_from_bytes = bip39_mnemonic_from_bytes (aWordList, aBufBytes, aBuf.length, &aOutput);
		NSAssert(WALLY_OK == aBip39_mnemonic_from_bytes, @"WALLY_OK == aBip39_mnemonic_from_bytes");
		NSString * aOutputString = [NSString stringWithUTF8String:aOutput];
		NSAssert (YES == [aMenemonic isEqualToString:aOutputString], @"YES == [aMenemonic isEqualToString:aOutputString]");
		NSData * aData = [aMenemonic dataUsingEncoding:NSUTF8StringEncoding];
		NSMutableData * aMutableData = [NSMutableData dataWithData:aData];
		const char aZero = 0;
		[aMutableData appendBytes:&aZero length:1];
		const int aBip39_mnemonic_validate = bip39_mnemonic_validate (aWordList, [aMutableData bytes]);
		NSAssert (WALLY_OK == aBip39_mnemonic_validate, @"0 == aBip39_mnemonic_validate");


		unsigned char * aOutBuf = malloc (aBuf.length);
		NSAssert (NULL != aOutBuf, @"NULL != aBytesOut");
		memset(aOutBuf, 0, aBuf.length);
		
		size_t aWritten = 0;
		const int aBip39_mnemonic_to_bytes = bip39_mnemonic_to_bytes (aWordList, aOutput, aOutBuf, aBuf.length, &aWritten);
		NSAssert(WALLY_OK == aBip39_mnemonic_to_bytes, @"WALLY_OK == aBip39_mnemonic_to_bytes");
		NSAssert (aBuf.length == aWritten, @"aHexInputData.length == aWritten");

		NSAssert (0 == memcmp (aBufBytes, aOutBuf, aWritten), @"0 == memcmp (aBufBytes, aOutBuf, aWritten)");
		wally_free_string (aOutput);
		free (aOutBuf);
		aOutBuf = NULL;
	}
}
-(void) test_288{
	// ported from 'src/test/test_bip39.py'
	const char * mnemonic = "panel jaguar rib echo witness mean please festival " \
		"issue item notable divorce conduct page tourist "    \
		"west off salmon ghost grit kitten pull marine toss " \
		"dirt oak gloom";
	NSLog (@"strlen (mnemonic): %@", @(strlen (mnemonic)));
	const int aBip39_mnemonic_validate = bip39_mnemonic_validate (NULL, mnemonic);
	NSAssert (WALLY_OK == aBip39_mnemonic_validate, @"WALLY_OK == aBip39_mnemonic_validate");

	unsigned char * aOutBuf = malloc (36);
	NSAssert (NULL != aOutBuf, @"NULL != aOutBuf");
	size_t aWritten = 0;
	const int aBip39_mnemonic_to_bytes = bip39_mnemonic_to_bytes (NULL, mnemonic, aOutBuf, 36, &aWritten);
	NSAssert (WALLY_OK == aBip39_mnemonic_to_bytes, @"WALLY_OK == aBip39_mnemonic_to_bytes");
	NSAssert (36 == aWritten, @"36 == aWritten");

	NSString * expectedString = @"9F8EE6E3A2FFCB13A99AA976AEDA5A2002ED" \
		"3DF97FCB9957CD863357B55AA2072D3EB2F9";
	NSData * expectedData = [expectedString hexToBytes];
	const char * expected = [expectedData bytes];
	NSAssert (0 == memcmp (expected, aOutBuf, aWritten), @"0 == memcmp (expected, aOutBuf, aWritten)");

	free (aOutBuf);
	aOutBuf = NULL;
}

//bip38: start
#define K_MAIN  0
#define K_TEST  7
#define K_COMP  256
#define K_EC    512
#define K_CHECK 1024
#define K_RAW   2048
#define K_ORDER 4096

- (void) test_bip38_vectors{
    NSLog(@"BIP38");
        
    NSMutableArray *cases = [NSMutableArray arrayWithObjects:
                             @[@"CBF4B9F70470856BB4F40F80B87EDB90865997FFEE6DF315AB166D713AF433A5",@"TestingOneTwoThree", @K_MAIN, @"6PRVWUbkzzsbcVac2qwfssoUJAN1Xhrg6bNk8J7Nzm5H7kxEbn2Nh2ZoGg"],
                             @[@"09C2686880095B1A4C249EE3AC4EEA8A014F11E6F986D0B5025AC1F39AFBD9AE",@"Satoshi", @K_MAIN, @"6PRNFFkZc2NZ6dJqFfhRoFNMR9Lnyj7dYGrzdgXXVMXcxoKTePPX1dWByq"],
                             @[@"CBF4B9F70470856BB4F40F80B87EDB90865997FFEE6DF315AB166D713AF433A5",@"TestingOneTwoThree", @(K_MAIN + K_COMP), @"6PYNKZ1EAgYgmQfmNVamxyXVWHzK5s6DGhwP4J5o44cvXdoY7sRzhtpUeo"],
                             @[@"09C2686880095B1A4C249EE3AC4EEA8A014F11E6F986D0B5025AC1F39AFBD9AE",@"Satoshi", @(K_MAIN + K_COMP + K_RAW), @"0142E00B76EA60B62F66F0AF93D8B5380652AF51D1A3902EE00726CCEB70CA636B5B57CE6D3E2F"],
                             @[@"3CBC4D1E5C5248F81338596C0B1EE025FBE6C112633C357D66D2CE0BE541EA18",@"jon", @(K_MAIN + K_COMP + K_RAW + K_ORDER), @"0142E09F8EE6E3A2FFCB13A99AA976AEDA5A2002ED3DF97FCB9957CD863357B55AA2072D3EB2F9"],  nil];
    
    //NSLog(@"%@",cases);
    
    for (id aCase in cases) {
        
        if([aCase isKindOfClass:[NSArray class]]){
            NSString* priv_key = aCase[0];
            NSString* passwd = aCase[1];
            
            int flags = [aCase[2] intValue];
            
            NSData * priv = [priv_key hexToBytes];
            NSData * pass = [passwd hexToBytes];
            char * aOutput = NULL;
            if (flags > K_RAW){
                //
                //
            }else{
#if 0
                //problem area
				// TODO: resolve link error:
				/*
				 Undefined symbols for architecture x86_64:
				 "_secp256k1_schnorr_verify", referenced from:
				 _wally_ec_sig_verify in liblibwally-core-ios.a(sign.o)
				 "_secp256k1_schnorr_sign", referenced from:
				 _wally_ec_sig_from_bytes in liblibwally-core-ios.a(sign.o)
				 ld: symbol(s) not found for architecture x86_64
				*/
                const int aBip38_mnemonic_from_bytes = bip38_from_private_key([priv bytes], priv.length, [pass bytes], pass.length, flags, &aOutput);
                
                NSAssert(WALLY_OK == aBip38_mnemonic_from_bytes, @"WALLY_OK == aBip38_mnemonic_from_bytes");

#endif
            }
            
        }
        
    }
}
//bip38: end



//AES: start

- (void) test_aes{
    
    NSMutableArray *cases =
    [NSMutableArray arrayWithObjects:
     @[@128,
       @"000102030405060708090a0b0c0d0e0f",
       @"00112233445566778899aabbccddeeff",
       @"69c4e0d86a7b0430d8cdb78070b4c55a" ],
     @[@192,
       @"000102030405060708090a0b0c0d0e0f1011121314151617",
       @"00112233445566778899aabbccddeeff",
       @"dda97ca4864cdfe06eaf70a0ec0d7191"],
     @[@256,
       @"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
       @"00112233445566778899aabbccddeeff",
       @"8ea2b7ca516745bfeafc49904b496089" ],
     /*AES-ECB test vectors from NIST sp800-38a.*/
     @[@128,
       @"2b7e151628aed2a6abf7158809cf4f3c",
       @"6bc1bee22e409f96e93d7e117393172a",
       @"3ad77bb40d7a3660a89ecaf32466ef97" ],
     @[@128,
       @"2b7e151628aed2a6abf7158809cf4f3c",
       @"ae2d8a571e03ac9c9eb76fac45af8e51",
       @"f5d3d58503b9699de785895a96fdbaaf" ],
     @[@128,
       @"2b7e151628aed2a6abf7158809cf4f3c",
       @"30c81c46a35ce411e5fbc1191a0a52ef",
       @"43b1cd7f598ece23881b00e3ed030688" ],
     @[@128,
       @"2b7e151628aed2a6abf7158809cf4f3c",
       @"f69f2445df4f9b17ad2b417be66c3710",
       @"7b0c785e27e8ad3f8223207104725dd4" ],
     @[@192,
       @"8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b",
       @"6bc1bee22e409f96e93d7e117393172a",
       @"bd334f1d6e45f25ff712a214571fa5cc" ],
     @[@192,
       @"8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b",
       @"ae2d8a571e03ac9c9eb76fac45af8e51",
       @"974104846d0ad3ad7734ecb3ecee4eef" ],
     @[@192,
       @"8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b",
       @"30c81c46a35ce411e5fbc1191a0a52ef",
       @"ef7afd2270e2e60adce0ba2face6444e" ],
     @[@192,
       @"8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b",
       @"f69f2445df4f9b17ad2b417be66c3710",
       @"9a4b41ba738d6c72fb16691603c18e0e" ],
     @[@256,
       @"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4",
       @"6bc1bee22e409f96e93d7e117393172a",
       @"f3eed1bdb5d2a03c064b5a7e3db181f8" ],
     @[@256,
       @"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4",
       @"ae2d8a571e03ac9c9eb76fac45af8e51",
       @"591ccb10d410ed26dc5ba74a31362870" ],
     @[@256,
       @"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4",
       @"30c81c46a35ce411e5fbc1191a0a52ef",
       @"b6ed21b99ca6f4f9f153e7b1beafed1d" ],
     @[@256,
       @"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4",
       @"f69f2445df4f9b17ad2b417be66c3710",
       @"23304b7a39f9f3ff067d8d8f9e24ecc7" ],
     nil];

    
    for (id aCase in cases) {
     
        if([aCase isKindOfClass:[NSArray class]]){
            
            NSInteger keyType = [[aCase objectAtIndex:0] integerValue];
            //int keyType = aCase[0];
            NSString* key = aCase[1];
            NSString* plain = aCase[2];
            NSString* cypher = aCase[3];
            
            [self aes_enc_dec:keyType key:key plain:plain cypher:cypher];
            
        }//if
        
    }//for
}

- (void) aes_enc_dec:(NSInteger)type key:(NSString*) key plain:(NSString*) plain cypher:(NSString*) cypher{
 
    unsigned char *charKey = (unsigned char *) [key UTF8String];
    unsigned char *charPlain = (unsigned char *) [plain UTF8String];
    //unsigned char *charCypher = (unsigned char *) [cypher UTF8String];
    
    NSData * keyData = [key hexToBytes];
    NSData * plainData = [plain hexToBytes];
    NSData * cypherData = [cypher hexToBytes];
    
    NSString* out_buf = [@"" stringByPaddingToLength: 2*cypherData.length withString:@"00" startingAtIndex:0];
    unsigned char *charOut = (unsigned char *) [out_buf UTF8String];
    
    NSData * outData = [out_buf hexToBytes];
    int enc = wally_aes(charKey, keyData.length, charPlain, plainData.length, AES_FLAG_ENCRYPT, charOut, outData.length);
    
    NSAssert (WALLY_OK == enc, @"WALLY_OK == wally_aes, ENCRYPT");
    
    /*if(WALLY_OK == enc)
        NSLog(@"AES%ld ENCRYPT: %d",(long)type, enc);*/
    
    
    int dec = wally_aes(charKey, keyData.length, charPlain, plainData.length, AES_FLAG_DECRYPT, charOut, outData.length);
    NSAssert (WALLY_OK == dec, @"WALLY_OK == wally_aes, DECRYPT");
    
    /*if(WALLY_OK == dec)
        NSLog(@"AES%ld DECRYPT: %d",(long)type, dec);*/

    
}

//AES: end


//MNEMONIC: start
#define LEN  ((int) 16)
#define PHRASES (int)(LEN * 8 / 11) //11 bits per phrase : 11
#define PHRASES_BYTES (int)(PHRASES * 11 + 7) / 8 // 8 # Bytes needed to store : 16

- (void) test_mnemonic{
    
    if(LEN == PHRASES_BYTES){
        
        size_t written = LEN;
        NSString *phrase = @"";
        unsigned char *buffer_out = (unsigned char *)calloc(LEN, sizeof(unsigned char));

        //reading file
        NSString* filePath = [[NSBundle mainBundle] pathForResource:@"english" ofType:@"txt"];
        NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        
        NSArray* words_list = [fileContents componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
        
        NSString *wordsString = [words_list componentsJoinedByString:@" "];
        const struct words * w = NULL;
        w = wordlist_init ([wordsString UTF8String]);
        

        for (int i = 0; i < (words_list.count - PHRASES); i++)
        {
            phrase = [self phrase_building:i end: (i + PHRASES) wordsList:words_list];
            
            const char *mnemonic = (const char *) [phrase UTF8String];
            
            int ret = mnemonic_to_bytes(w, mnemonic, buffer_out, sizeof(buffer_out), &written);
            NSAssert (WALLY_OK == ret, @"WALLY_OK == mnemonic_to_bytes");
            
            /*if( ret == WALLY_OK){
                NSLog(@"Success");
            }else if( ret == WALLY_ERROR){
                NSLog(@"General error");
            }else if( ret == WALLY_EINVAL){
                NSLog(@"Invalid argument");
            }else if( ret == WALLY_ENOMEM){
                NSLog(@"malloc() failed");
            }*/
            
        }//for
    }//if
}

- (NSString *) phrase_building: (int)start end: (int)end wordsList: (NSArray*) wl{
    
    NSString *phrase = @"";
    for (int i = start; i <end; i++){
        phrase = [phrase stringByAppendingString:[wl objectAtIndex: i] ];
        phrase = [phrase stringByAppendingString:@" "];
    }
    
    return phrase;
}


//MNEMONIC: end

//scrypt: start
- (void) test_scrypt{
    
    NSMutableArray *cases =
    [NSMutableArray arrayWithObjects:
     @[@"",@"",@16,@1,@1,@64,
       @"77 d6 57 62 38 65 7b 20 3b 19 ca 42 c1 8a 04 97 \
       f1 6b 48 44 e3 07 4a e8 df df fa 3f ed e2 14 42 \
       fc d0 06 9d ed 09 48 f8 32 6a 75 3a 0f c8 1f 17 \
       e8 d3 e0 fb 2e 0d 36 28 cf 35 e2 0c 38 d1 89 06"],
     @[@"password",@"NaCl",@1024, @8, @16, @64,
       @"fd ba be 1c 9d 34 72 00 78 56 e7 19 0d 01 e9 fe \
       7c 6a d7 cb c8 23 78 30 e7 73 76 63 4b 37 31 62 \
       2e af 30 d9 2e 22 a3 88 6f f1 09 27 9d 98 30 da \
       c7 27 af b9 4a 83 ee 6d 83 60 cb df a2 cc 06 40"],
     @[@"pleaseletmein", @"SodiumChloride",@16384, @8, @1, @64,
       @"70 23 bd cb 3a fd 73 48 46 1c 06 cd 81 fd 38 eb \
       fd a8 fb ba 90 4f 8e 3e a9 b5 43 f6 54 5d a1 f2 \
       d5 43 29 55 61 3f 0f cf 62 d4 97 05 24 2a 9a f9 \
       e6 1e 85 dc 0d 65 1e 40 df cf 01 7b 45 57 58 87"],
     @[@"pleaseletmein", @"SodiumChloride",@1048576, @8, @1, @64,
       @"21 01 cb 9b 6a 51 1a ae ad db be 09 cf 70 f8 81 \
       ec 56 8d 57 4a 2f fd 4d ab e5 ee 98 20 ad aa 47 \
       8e 56 fd 8f 4b a5 d0 9f fa 1c 6d 92 7c 40 f4 c3 \
       37 30 40 49 e8 a9 52 fb cb f4 5c 6f a7 7a 41 a4"],nil];
    
    
    
    for (id aCase in cases) {
        
        if([aCase isKindOfClass:[NSArray class]]){
            
            NSString* passwd    = aCase[0];
            NSInteger length    = [[aCase objectAtIndex:5] integerValue];
            NSString* expected  = [aCase[6] stringByReplacingOccurrencesOfString:@" " withString:@""];
            
            if([expected length] == (length*2)){
                
                uint32_t cost = (uint32_t) [[aCase objectAtIndex:2] integerValue];
                uint32_t block = (uint32_t) [[aCase objectAtIndex:3] integerValue];
                uint32_t parallelism = (uint32_t) [[aCase objectAtIndex:4] integerValue];
                
                NSData * expectedData = [expected hexToBytes];
                NSString* out_buf = [@"" stringByPaddingToLength: expectedData.length withString:@"0" startingAtIndex:0];
                unsigned char *pass = (unsigned char *) [passwd UTF8String];
                unsigned char *salt = (unsigned char *) [aCase[1] UTF8String];
                unsigned char *outBuf = (unsigned char *) [out_buf UTF8String];
                
                int ret = wally_scrypt(pass, sizeof(pass), salt, sizeof(salt), cost, block, parallelism, outBuf, sizeof(outBuf));
                NSAssert (WALLY_OK == ret, @"WALLY_OK == wally_scrypt");
                
                /*if( ret == WALLY_OK){
                    NSLog(@"Success");
                }else if( ret == WALLY_ERROR){
                    NSLog(@"General error");
                }else if( ret == WALLY_EINVAL){
                    NSLog(@"Invalid argument");
                }else if( ret == WALLY_ENOMEM){
                    NSLog(@"malloc() failed");
                }*/
            }
        }//if
        
    }//for
}
//scrypt: end


-(void) test{
	self.fDebugTextView.text = @"";
	NSMutableArray * aLogArray = [[NSMutableArray alloc] init];
	[aLogArray addObject: @"begin test…"];
	[aLogArray addObject:[libwally_core_ios staticTest]];
	libwally_core_ios * aObject = [[libwally_core_ios alloc] init];
	[aLogArray addObject: [aObject objectTest]];
	self.fDebugTextView.text = [aLogArray componentsJoinedByString:@";\n"];
	
	// Testing wally_bip39
	[aLogArray addObject:@"testing wally_bip39 (ported from 'src/test/test_bip39.py')"];
	[self test_all_langs];
	[aLogArray addObjectsFromArray:[self test_load_word_list]];
	[self test_bip39_vectors];
	[self test_288];
	NSString * testOK = @"#libwally-core-ios.bip39 OK";
	[aLogArray addObject:testOK];
	NSLog (@"%@", testOK);
    //mnemonic_to_bytes

    [aLogArray addObject:@"\n"];
    [aLogArray addObject:@"testing aes (ported from 'src/test/test_aes.py')"];
    [self test_aes];
    testOK = @"#libwally-core-ios.aes OK";
    [aLogArray addObject:testOK];
    
    [aLogArray addObject:@"\n"];
    [aLogArray addObject:@"testing mnemonic (ported from 'src/test/test_mnemonic.py')"];
    [self test_mnemonic];
    testOK = @"#libwally-core-ios.mnemonic OK";
    [aLogArray addObject:testOK];

    [aLogArray addObject:@"\n"];
    [aLogArray addObject:@"testing scrypt (ported from 'src/test/test_scrypt.py')"];
    [self test_scrypt];
    testOK = @"#libwally-core-ios.scrypt OK";
    [aLogArray addObject:testOK];
    
	self.fDebugTextView.text = [aLogArray componentsJoinedByString:@"\n"];
}
@end
