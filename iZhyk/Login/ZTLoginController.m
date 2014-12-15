//
//  ZTLoginController.m
//  iZhyk
//
//  Created by ZRazor on 24.11.14.
//  Copyright (c) 2014 Farpost. All rights reserved.
//

#import "ZTLoginController.h"
#import "ZTZhyk.h"
#import "ZTRequester.h"
#import <UIImageView+AFNetworking.h>
#import <AFHTTPRequestOperationManager.h>

@implementation ZTLoginController {
    UIActivityIndicatorView* captchaLoadIndicator;
    UIActivityIndicatorView* loginActivity;
    NSUserDefaults* userDefaults;
    ZTZhyk *zhyk;
}

- (IBAction)unwindToLoginController:(UIStoryboardSegue *)unwindSegue
{
    [zhyk doLogout];
    [userDefaults setBool:NO forKey:@"auth"];
    [userDefaults setValue:@"" forKey:@"login"];
    _loginField.text = @"";
    _passwordField.text = @"";
    _captchaField.text = @"";
    [self setVisibleByTag:2 visible:NO];
    [self setVisibleByTag:1 visible:YES];
}

- (void)showAlert:(NSString *)msg
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Ошибка"
                                                        message:msg
                                                       delegate:nil
                                              cancelButtonTitle:@"Закрыть"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)setVisibleByTag:(NSInteger)tag visible:(BOOL)visible
{
    for(UIView *subview in self.view.subviews) {
        if (subview.tag == tag) {
            subview.hidden = !visible;
        }
    }
}

-(void)viewDidLoad
{
    zhyk = [ZTZhyk sharedInstance];
    userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:@"auth"]) {
        [ZTRequester loadCookies];
        _loginField.text = [userDefaults valueForKey:@"login"];
        [self activateLoginProcess:YES];
        [zhyk checkAuth:^(BOOL loggedIn, BOOL isError, NSString *errorMsg) {
            [self activateLoginProcess:NO];
            if (loggedIn) {
                [self performSegueWithIdentifier:@"loginSegue" sender:self];
            } else {
                if (isError) {
                    [userDefaults setBool:NO forKey:@"auth"];
                    [userDefaults setValue:@"" forKey:@"login"];
                    [zhyk doLogout];
                    [self showAlert:errorMsg];
                }
            }
        }];
    } else {
        [ZTRequester deleteCookies];
    }
}

- (void)activateLoginProcess:(BOOL)activate
{
    _loginButton.hidden = activate;
    _loginField.enabled = !activate;
    _passwordField.enabled = !activate;
    if (activate) {
        loginActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        loginActivity.center = CGPointMake(self.view.center.x, _loginButton.center.y);
        [self.view addSubview:loginActivity];
        [loginActivity startAnimating];
    } else {
        [loginActivity removeFromSuperview];
    }
}

- (void)activateCaptchaProcess:(BOOL)activate
{
    _captchaField.enabled = !activate;
    _captchaButton.hidden = activate;
}

- (IBAction)loginClick:(UIButton *)sender {
    if ([_loginField.text isEqualToString:@""] || [_passwordField.text isEqualToString:@""]) {
        [self showAlert:@"Логин и пароль не должны быть пустыми"];
        return;
    }
    [self activateLoginProcess:YES];
    [zhyk authBeforeCaptchaWithLogin:_loginField.text password:_passwordField.text block:^(NSString* imgUrl, BOOL isError, NSString* errorMsg){
        [self activateLoginProcess:NO];
        if (!isError) {
            [self setVisibleByTag:1 visible:NO];
            [self setVisibleByTag:2 visible:YES];
            [self startCaptchaLoadingIndicator];
            [self loadCaptchaImg:imgUrl];
        } else {
            [self showAlert:errorMsg];
        }
    }];
}

- (IBAction)captchaClick:(UIButton *)sender {
    if ([_captchaField.text isEqualToString:@""]) {
        [self showAlert:@"Строка не должна быть пустой"];
        return;
    }
    [self activateCaptchaProcess:YES];
    UIActivityIndicatorView* captchaActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    captchaActivity.center = _captchaButton.center;
    [self.view addSubview:captchaActivity];
    [captchaActivity startAnimating];
    [zhyk authAfterCaptcha:_captchaField.text block:^(BOOL isError, NSString* errorMsg) {
        [captchaActivity removeFromSuperview];
        [self activateCaptchaProcess:NO];
        if (!isError) {
            [userDefaults setBool:YES forKey:@"auth"];
            [userDefaults setValue:_loginField.text forKey:@"login"];
            [self performSegueWithIdentifier:@"loginSegue" sender:self];
        } else {
            [self setVisibleByTag:2 visible:NO];
            [self setVisibleByTag:1 visible:YES];
            _captchaField.text = @"";
            [self showAlert:errorMsg];
        }
    }];
}

- (IBAction)updateClick:(UIButton *)sender {
    [self startCaptchaLoadingIndicator];
    [zhyk reloadCaptchaImg:^(NSString *imgUrl, BOOL isError, NSString* errorMsg) {
        if (!isError) {
            [self loadCaptchaImg:imgUrl];
        } else {
            [self setVisibleByTag:2 visible:NO];
            [self setVisibleByTag:1 visible:YES];
            [self showAlert:errorMsg];
        }
    }];
}

- (IBAction)forgetPasswordClick:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://zhyk.ru/forum/login.php?do=lostpw"]];
}

- (IBAction)registerClick:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://zhyk.ru/forum/register.php"]];
}

-(void)startCaptchaLoadingIndicator
{
    _captchaImage.image = nil;
    captchaLoadIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    captchaLoadIndicator.center = _captchaImage.center;
    [self.view addSubview:captchaLoadIndicator];
    [captchaLoadIndicator startAnimating];
}

-(void)loadCaptchaImg:(NSString *)imgUrl
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:imgUrl]];
    
    [_captchaImage setImageWithURLRequest:request
                         placeholderImage:nil
                                  success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                      
                                      [captchaLoadIndicator removeFromSuperview];
                                      captchaLoadIndicator = nil;
                                      // do image resize here
                                      
                                      // then set image view
                                      
                                      _captchaImage.image = image;
                                  }
                                  failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                      [captchaLoadIndicator removeFromSuperview];
                                      captchaLoadIndicator = nil;
                                      
                                      // do any other error handling you want here
                                  }];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
