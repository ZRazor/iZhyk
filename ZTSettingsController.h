//
//  ZTSettingsController.h
//  iZhyk
//
//  Created by ZRazor on 26.11.14.
//  Copyright (c) 2014 Farpost. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZTSettingsController : UITableViewController
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
- (IBAction)timeSliderChange:(UISlider *)sender;
@property (weak, nonatomic) IBOutlet UISlider *timeSlider;
@property (weak, nonatomic) IBOutlet UILabel *logoutLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *colorSegment;
- (IBAction)colorSegmentChange:(UISegmentedControl *)sender;

@end
