//
//  ZTSettingsController.m
//  iZhyk
//
//  Created by ZRazor on 26.11.14.
//  Copyright (c) 2014 Farpost. All rights reserved.
//

#import "ZTSettingsController.h"
#import "ZTZhyk.h"
#import "UIColor+JSQMessages.h"

#define TIME_LABEL @"Частота обновления чата: %.02f сек"
#define LOGOUT_LABEL @"%@ - Выйти"

@implementation ZTSettingsController

- (BOOL)color:(UIColor *)color1 isEqualToColor:(UIColor *)color2 withTolerance:(CGFloat)tolerance {
    
    CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
    [color1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [color2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    return
    fabs(r1 - r2) <= tolerance &&
    fabs(g1 - g2) <= tolerance &&
    fabs(b1 - b2) <= tolerance &&
    fabs(a1 - a2) <= tolerance;
}


-(void)viewDidLoad
{
    UIColor *mainColor = [[ZTZhyk sharedInstance] loadMainColor];
    self.navigationController.navigationBar.tintColor = mainColor;
    [_logoutLabel setTextColor:mainColor];
    float timeInterval = [[NSUserDefaults standardUserDefaults] floatForKey:@"updateTimerInterval"];
    _timeLabel.text = [NSString stringWithFormat:TIME_LABEL, timeInterval];
    _timeSlider.value = timeInterval;
    _logoutLabel.text = [NSString stringWithFormat:LOGOUT_LABEL, [ZTZhyk sharedInstance].login];
    if ([self color:mainColor isEqualToColor:[UIColor jsq_messageBubbleBlueColor] withTolerance:0.01]) {
        [_colorSegment setSelectedSegmentIndex:1];
    } else if ([self color:mainColor isEqualToColor:[UIColor jsq_messageBubbleGreenColor] withTolerance:0.01]) {
        [_colorSegment setSelectedSegmentIndex:2];
    }
    
}

- (IBAction)timeSliderChange:(UISlider *)sender {
    [[NSUserDefaults standardUserDefaults] setFloat:sender.value forKey:@"updateTimerInterval"];
    _timeLabel.text = [NSString stringWithFormat:TIME_LABEL, sender.value];
}
- (IBAction)colorSegmentChange:(UISegmentedControl *)sender {
    UIColor *mainColor = [UIColor jsq_messageBubbleRedColor];
    switch (sender.selectedSegmentIndex) {
        case 0:
            break;
        case 1:
            mainColor = [UIColor jsq_messageBubbleBlueColor];
            break;
        case 2:
            mainColor = [UIColor jsq_messageBubbleGreenColor];
            break;
            
    }
    [[ZTZhyk sharedInstance] saveMainColor:mainColor];
}

@end
