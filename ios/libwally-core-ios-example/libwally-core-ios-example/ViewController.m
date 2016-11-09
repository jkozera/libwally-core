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
}

@end
