//
//  ViewController.m
//  libwally-core-ios-example
//
//  Created by isidoro carlo ghezzi on 11/9/16.
//  Copyright © 2016 isidoro carlo ghezzi. All rights reserved.
//

#import "ViewController.h"
#import "LibwallyCoreUnitTest.h"

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
        
    /*LibwallyCoreUnitTest * aTest = [[LibwallyCoreUnitTest alloc] initWithDebugView:self.fDebugTextView];
    [aTest test_hash];*/
    

}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (IBAction)actionTest:(id)sender {
    
    [NSThread detachNewThreadSelector:@selector(start_test) toTarget:self withObject:nil];
}
- (void) start_test{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        LibwallyCoreUnitTest * aTest = [[LibwallyCoreUnitTest alloc] initWithDebugView:self.fDebugTextView];
        [aTest test];
    });

}

@end
