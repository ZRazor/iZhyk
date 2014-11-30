//
//  ZTRequester.h
//  iZhyk
//
//  Created by ZRazor on 23.11.14.
//  Copyright (c) 2014 Farpost. All rights reserved.
//

#import <Foundation/Foundation.h>

#define API_GET_CAPTCHA @"http://api.recaptcha.net/challenge"
#define API_GET_CAPTCHA_RELOAD @"http://www.google.com/recaptcha/api/reload"
#define API_GET_CAPTCHA_IMG @"http://www.google.com/recaptcha/api/image?c="
#define API_BASE_URL @"http://zhyk.ru/forum/"
#define API_LOGIN_URL @"login.php?do=login"
#define API_DOLOGIN_URL @"login.php?do=dologin"
#define API_GET_CHAT @"misc.php?show=ccbmessages"
#define API_MAIN @"index.php"
#define API_SEND_CHAT_MSG @"misc.php"


@interface ZTRequester : NSObject

+ (void)saveCookies;

+ (void)loadCookies;

+ (void)deleteCookies;

+ (void)doPostRequest:(NSString *)url jsonAns:(BOOL)jsonAns params:(NSDictionary *)params block:(void (^)(id result, NSError *error))block;

+ (void)doGetRequest:(NSString *)url jsonAns:(BOOL)jsonAns params:(NSDictionary *)params block:(void (^)(id result, NSError *error))block;

+ (void)doRequest:(NSString *)url isBaseUrl:(BOOL)isBaseUrl isPost:(BOOL)isPost jsonAns:(BOOL)jsonAns params:(NSDictionary *)params block:(void (^)(id result, NSError *error))block;

@end
