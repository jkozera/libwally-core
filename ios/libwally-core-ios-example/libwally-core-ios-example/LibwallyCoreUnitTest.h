//
//  LibwallyCoreUnitTest.h
//  libwally-core-ios-example
//
//  Created by isidoro carlo ghezzi on 11/10/16.
//  Copyright © 2016 isidoro carlo ghezzi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



@interface LibwallyCoreUnitTest : NSObject
-(instancetype)initWithDebugView:(UITextView *) theDebugView;
-(void) test;


- (void) test_bip38_vectors;
- (void) test_aes;
- (void) test_mnemonic;



@end
