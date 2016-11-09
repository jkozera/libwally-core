//
//  ViewController.m
//  libwally-core-ios-example
//
//  Created by isidoro carlo ghezzi on 11/9/16.
//  Copyright © 2016 isidoro carlo ghezzi. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *fHeaderLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.fHeaderLabel.text = [NSString stringWithFormat:@"libwally-core-ios-example\nCompilation date and time:\n%s %s", __DATE__, __TIME__]
	;}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


@end
