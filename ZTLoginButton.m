//
//  ZTLoginButton.m
//  iZhyk
//
//  Created by ZRazor on 25.11.14.
//  Copyright (c) 2014 Farpost. All rights reserved.
//

#import "ZTLoginButton.h"
#import "ZTZhyk.h"

@implementation ZTLoginButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: rect cornerRadius: 5];
    [[[ZTZhyk sharedInstance] loadMainColor] setFill];
    [rectanglePath fill];
}


@end
