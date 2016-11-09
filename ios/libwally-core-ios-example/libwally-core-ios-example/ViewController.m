//
//  ViewController.m
//  libwally-core-ios-example
//
//  Created by isidoro carlo ghezzi on 11/9/16.
//  Copyright © 2016 isidoro carlo ghezzi. All rights reserved.
//

#import "ViewController.h"
#import "libwally-core-ios/libwally_core_ios.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *fHeaderLabel;
@property (weak, nonatomic) IBOutlet UITextView *fDebugTextView;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.fHeaderLabel.text = [NSString stringWithFormat:@"libwally-core-ios-example\nCompilation date and time:\n%s %s", __DATE__, __TIME__];
	self.fDebugTextView.text = @"";
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (IBAction)actionTest:(id)sender {
	self.fDebugTextView.text = @"begin test…";
	NSMutableArray * aLogArray = [[NSMutableArray alloc] init];
	[aLogArray addObject:[libwally_core_ios staticTest]];
	libwally_core_ios * aObject = [[libwally_core_ios alloc] init];
	[aLogArray addObject: [aObject objectTest]];
	self.fDebugTextView.text = [aLogArray componentsJoinedByString:@";\n"];

	// Testing wally_bip39
	char * aLanguages = NULL;
	const int aBip39_get_languages = bip39_get_languages (&aLanguages);
	NSLog (@"aBip39_get_languages: %@, aLanguages: %s", @(aBip39_get_languages), aLanguages);

	NSString * aLanguagesString = [NSString stringWithUTF8String:aLanguages];
	wally_free_string (aLanguages);
	NSArray * aLanguagesArray = [aLanguagesString componentsSeparatedByString: @" "];

	for (NSString * aKey in aLanguagesArray){
		const char * aCKey = [aKey cStringUsingEncoding:NSUTF8StringEncoding];
		NSLog (@"%s", aCKey);
		const struct words * aWords = NULL;
		const int aBip39_get_wordlist = bip39_get_wordlist (aCKey, &aWords);
		NSLog (@"aBip39_get_wordlist: %@; aWords.len: %@", @(aBip39_get_wordlist), @(aWords->len));
		for (size_t i = 0; i < aWords->len && i < 100; ++i){
			NSString * aString = [NSString stringWithUTF8String:aWords->indices [i]];
			NSString * aLog = [NSString stringWithFormat:@"%@/%@ - %s - %@;", @(i+1), @(aWords->len), aCKey, aString];
			[aLogArray addObject:aLog];
		}
	}
	self.fDebugTextView.text = [aLogArray componentsJoinedByString:@"\n"];
}

@end
