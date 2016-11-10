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
		for (size_t i = 0; i < aWords->len && i < 100; ++i){
			NSString * aString = [NSString stringWithUTF8String:aWords->indices [i]];
			NSString * aLog = [NSString stringWithFormat:@"%@/%@ - %@ - %@;", @(i+1), @(aWords->len), aKey, aString];
			[aLogArray addObject:aLog];
		}
	}
	return aLogArray;
}

- (void) test_bip39_vectors{
	const struct words * aWordList = [self get_wordlist:nil];
	for (NSArray * aCase in self.fVectorsDictionary [@"english"]){
		NSLog (@"%@", aCase.description);
		NSString * aHexInputString = aCase [0];
		NSString  * aMenemonic = aCase [1];
		NSData * aHexInputData = [aHexInputString hexToBytes];
		char * aOutput = NULL;
		const int aBip39_mnemonic_from_bytes = bip39_mnemonic_from_bytes (aWordList, [aHexInputData bytes], aHexInputData.length, &aOutput);
		NSAssert(WALLY_OK == aBip39_mnemonic_from_bytes, @"WALLY_OK == aBip39_mnemonic_from_bytes");
		NSString * aOutputString = [NSString stringWithUTF8String:aOutput];
		NSAssert (YES == [aMenemonic isEqualToString:aOutputString], @"YES == [aMenemonic isEqualToString:aOutputString]");
		NSData * aData = [aMenemonic dataUsingEncoding:NSUTF8StringEncoding];
		NSMutableData * aMutableData = [NSMutableData dataWithData:aData];
		const char aZero = 0;
		[aMutableData appendBytes:&aZero length:1];
		const int aBip39_mnemonic_validate = bip39_mnemonic_validate (aWordList, [aMutableData bytes]);
		NSAssert (0 == aBip39_mnemonic_validate, @"0 == aBip39_mnemonic_validate");
		wally_free_string (aOutput);
	}
}

-(void) test{
	self.fDebugTextView.text = @"begin test…";
	NSMutableArray * aLogArray = [[NSMutableArray alloc] init];
	[aLogArray addObject:[libwally_core_ios staticTest]];
	libwally_core_ios * aObject = [[libwally_core_ios alloc] init];
	[aLogArray addObject: [aObject objectTest]];
	self.fDebugTextView.text = [aLogArray componentsJoinedByString:@";\n"];
	
	// Testing wally_bip39
	[self test_all_langs];
	[aLogArray addObjectsFromArray:[self test_load_word_list]];
	self.fDebugTextView.text = [aLogArray componentsJoinedByString:@"\n"];
	[self test_bip39_vectors];
	
}
@end
