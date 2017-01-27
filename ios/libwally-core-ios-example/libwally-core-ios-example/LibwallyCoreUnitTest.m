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
                
                //problem area
                const int aBip38_mnemonic_from_bytes = bip38_from_private_key([priv bytes], priv.length, [pass bytes], pass.length, flags, &aOutput);
                
                NSAssert(WALLY_OK == aBip38_mnemonic_from_bytes, @"WALLY_OK == aBip38_mnemonic_from_bytes");
            }
            
        }
        
    }
    
    
}
//bip38: end



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
	NSString * testOK = @"libwally-core-ios.bip39 OK";
	[aLogArray addObject:testOK];
	NSLog (@"%@", testOK);
	self.fDebugTextView.text = [aLogArray componentsJoinedByString:@"\n"];
}
@end
