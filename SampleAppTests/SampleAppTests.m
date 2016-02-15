//
//  SampleAppTests.m
//  SampleAppTests
//
//  Created by Johannes Plunien on 15/02/16.
//  Copyright © 2016 Johannes Plunien. All rights reserved.
//

#import <KIF/KIF.h>

@interface SampleAppTests : KIFTestCase

@end

@implementation SampleAppTests

- (void)testRows
{
    for (NSInteger i = 0; i < 50; i++) {
        [tester waitForViewWithAccessibilityLabel:[NSString stringWithFormat:@"Row %zd", i]];
    }
}

@end