//
//  ZTCaptchaField.m
//  iZhyk
//
//  Created by ZRazor on 25.11.14.
//  Copyright (c) 2014 Farpost. All rights reserved.
//

#import "ZTCaptchaField.h"

@implementation ZTCaptchaField

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
    UIColor* color2 = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    UIColor* color4 = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.039];
    
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners: UIRectCornerAllCorners cornerRadii: CGSizeMake(5, 5)];
    [rectanglePath closePath];
    [color2 setFill];
    [rectanglePath fill];
    [color4 setStroke];
    rectanglePath.lineWidth = 1;
    [rectanglePath stroke];
}


@end
