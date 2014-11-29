//
//  ZTLoginController.h
//  iZhyk
//
//  Created by ZRazor on 24.11.14.
//  Copyright (c) 2014 Farpost. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZTLoginController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *loginField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIImageView *captchaImage;
@property (weak, nonatomic) IBOutlet UITextField *captchaField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *captchaButton;
@property (weak, nonatomic) IBOutlet UIButton *updateButton;
- (IBAction)loginClick:(UIButton *)sender;
- (IBAction)captchaClick:(UIButton *)sender;
- (IBAction)updateClick:(UIButton *)sender;
- (IBAction)forgetPasswordClick:(UIButton *)sender;
- (IBAction)registerClick:(UIButton *)sender;

@end
