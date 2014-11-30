#import "ZTZhyk.h"
#import "ZTRequester.h"
#import "ZTParser.h"
#import <CommonCrypto/CommonDigest.h>

#define STRING_BAD_CAPTCHA @"Введённая вами строка не совпадает"
#define STRING_BAD_PASSWORD @"Вы ввели неправильное имя или пароль"
#define STRING_LOGIN_SUCCESS @"Спасибо, что зашли"
#define STRING_IP_DENIED @"К Вашему аккаунту применена привязка"
#define STRING_BANNDED @"Вы использовали предел попыток входа"
#define STRING_CHAT_ENABLED @"cybchatmenuccbox"
#define STRING_NOT_CHAT @"var SECURITYTOKEN ="

@implementation ZTZhyk {
    NSString* humanVerifyHash;
    NSString* captchaHash;
    NSString* captchaImgHash;
    NSString* securityToken;
    NSString* inputLogin;
    NSString* passwordMD5;
    NSString* lastMsgId;
}

-(instancetype)initUniqueInstance
{
    return [super init];
}

+(ZTZhyk *)sharedInstance
{
    static dispatch_once_t pred;
    static ZTZhyk *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[super alloc] initUniqueInstance];
        shared.authStatus = asLoggedOut;
    });
    return shared;
}

- (UIColor *)loadMainColor
{
    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"mainColor"];
    return [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
}

-(void)saveMainColor:(UIColor *)mainColor
{
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:mainColor];
    [[NSUserDefaults standardUserDefaults] setObject:colorData forKey:@"mainColor"];
}

- (NSString*)md5HexDigest:(NSString*)input {
    const char* str = [input UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

-(void)clearFields
{
    humanVerifyHash = @"";
    captchaHash = @"";
    captchaImgHash = @"";
    inputLogin = @"";
    passwordMD5 = @"";
    securityToken = @"";
    lastMsgId = @"";
    _login = @"";
    _authStatus = asLoggedOut;
}

-(void)doLogout
{
    [ZTRequester deleteCookies];
    [self clearFields];
}


-(void)authBeforeCaptchaWithLogin:(NSString *)login password:(NSString *)password block:(void (^)(NSString* imgUrl, BOOL isError, NSString* errorMsg))block
{
    if (_authStatus != asLoggedOut) {
        block(nil, YES, @"Вы уже вошли");
    }
    inputLogin = login;
    passwordMD5 = [self md5HexDigest:password];
    [ZTRequester doPostRequest:API_LOGIN_URL jsonAns:NO params:@{
                                                                    @"vb_login_username":inputLogin,
                                                                    @"cookieuser":@"1",
                                                                    @"vb_login_password":@"",
                                                                    @"s":@"",
                                                                    @"securitytoken":@"guest",
                                                                    @"do":@"login",
                                                                    @"vb_login_md5password":passwordMD5,
                                                                    @"vb_login_md5password_utf":passwordMD5
                                                                 }
         block:^(id result, NSError *error) {
             __block NSString* errorMsg = @"Ошибка соединения с сервером";
             __block BOOL isError = YES;
             if (result && !error) {
                 NSString *pageHtml = [[NSString alloc] initWithData:result encoding:NSWindowsCP1251StringEncoding];
                 captchaHash = [ZTParser parseCaptchaHash:pageHtml];
                 humanVerifyHash = [ZTParser parseHumanVerifyHash:pageHtml];
                 isError = NO;
                 if (!([captchaHash isEqualToString:@""] || [humanVerifyHash isEqualToString:@""])) {
                     [ZTRequester doRequest:API_GET_CAPTCHA isBaseUrl:NO isPost:NO jsonAns:NO params:@{@"k":captchaHash} block:^(id result, NSError *error) {
                         isError = YES;
                         errorMsg = @"Ошибка получения капчи";
                         if (result && !error) {
                             NSString *jsAns = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                             captchaImgHash = [ZTParser parseCaptchaImgHash:jsAns];
                             errorMsg = @"Ошибка получения капчи";
                             if (![captchaImgHash isEqualToString:@""]) {
                                 _authStatus = asBeforeCaptcha;
                                 isError = NO;
                                 block([API_GET_CAPTCHA_IMG stringByAppendingString:captchaImgHash], NO, nil);
                             }
                         }
                         if (isError) {
                             block(nil, YES, errorMsg);
                         }
                     }];
                 }
             }
             if (isError) {
                 block(nil, YES, errorMsg);
             }
     }];
}

-(void)reloadCaptchaImg:(void (^)(NSString* imgUrl, BOOL isError, NSString* errorMsg))block
{
    if (_authStatus != asBeforeCaptcha) {
        block(nil, YES, @"Очень плохая ошибка, если вы ее видите, значит разработчик где-то накосячил");
        return;
    }
    _authStatus = asLoggedOut;
    [ZTRequester doRequest:API_GET_CAPTCHA_RELOAD isBaseUrl:NO isPost:NO jsonAns:NO params:@{
                                                                                             @"c":captchaImgHash,
                                                                                             @"k":captchaHash,
                                                                                             @"reason":@"[object%20MouseEvent]",
                                                                                             @"type":@"image",
                                                                                             @"lang":@"ru"
                                                                                             }
    block:^(id result, NSError *error) {
        NSString* errorMsg = @"Ошибка получения капчи";
        BOOL isError = YES;
        if (result && !error) {
            NSString *jsAns = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
            captchaImgHash = [ZTParser parseCaptchaImgHashAfterReload:jsAns];
            if (![captchaImgHash isEqualToString:@""]) {
                isError = NO;
                _authStatus = asBeforeCaptcha;
                block([API_GET_CAPTCHA_IMG stringByAppendingString:captchaImgHash], NO, nil);
            }
        }
        if (isError) {
            block(nil, YES, errorMsg);
        }
    }];
}

-(void)parseMainPage:(void (^)(BOOL isError, NSString* errorMsg))block
{
    [ZTRequester doGetRequest:API_MAIN jsonAns:NO params:nil block:^(id result, NSError *error) {
        BOOL isError = YES;
        NSString *errorMsg = @"Ошибка соединения с сервером";
        if (result && !error) {
            NSString *newPageHtml = [[NSString alloc] initWithData:result encoding:NSWindowsCP1251StringEncoding];
            if ([newPageHtml rangeOfString:STRING_IP_DENIED].location != NSNotFound) {
                errorMsg = @"Вход в данный аккаунт с этого IP запрещен";
            } else if ([newPageHtml rangeOfString:STRING_CHAT_ENABLED].location == NSNotFound) {
                errorMsg = @"К сожалению чат вам недоступен. У вас либо недостаточно сообщений, либо вы забанены";
            } else {
                securityToken = [ZTParser parseSecurityToken:newPageHtml];
                if ([securityToken isEqualToString:@""] || [securityToken isEqualToString:@"guest"]) {
                    errorMsg = @"Неизвестная ошибка авторизации";
                } else {
                    isError = NO;
//                    NSLog(@"%@", newPageHtml);
                    _userId = [ZTParser parseUserId:newPageHtml];
                    _login = [ZTParser parseUserLogin:newPageHtml];
                    _authStatus = asLoggedIn;
                    block(NO, nil);
                }
            }
        }
        if (isError) {
            block(YES, errorMsg);
        }
    }];
}

-(void)checkAuth:(void (^)(BOOL loggedIn, BOOL isError, NSString* errorMsg))block
{
    [self parseMainPage:^(BOOL isError, NSString *errorMsg) {
        if (!isError) {
            block(YES, NO, nil);
        } else if ([securityToken isEqualToString:@"guest"]) {
            block(NO, YES, @"Срок авторизации уже истек");
        } else {
            block(NO, YES, errorMsg);
        }
    }];
}

-(void)authAfterCaptcha:(NSString *)captchaText block:(void (^)(BOOL isError, NSString* errorMsg))block
{
    if (_authStatus != asBeforeCaptcha) {
        block(YES, @"Очень плохая ошибка, если вы ее видите, значит разработчик где-то накосячил");
        return;
    }
    _authStatus = asLoggedOut;
    [ZTRequester doPostRequest:API_DOLOGIN_URL jsonAns:NO params:@{
                                                                 @"humanverify[hash]":humanVerifyHash,
                                                                 @"vb_login_username":inputLogin,
                                                                 @"vb_login_password":passwordMD5,
                                                                 @"cookieuser":@"1",
                                                                 @"vb_login_password":@"",
                                                                 @"s":@"",
                                                                 @"securitytoken":@"guest",
                                                                 @"do":@"dologin",
                                                                 @"url":@"http://zhyk.ru/forum/index.php",
                                                                 @"recaptcha_challenge_field":captchaImgHash,
                                                                 @"recaptcha_response_field":captchaText,
                                                                 @"postvars":@"",
                                                                 @"logintype":@"",
                                                                 @"cssprefs":@""
                                                                 }
     block:^(id result, NSError *error) {
         __block NSString *errorMsg = @"Ошибка соединения с сервером";
         __block BOOL isError = YES;
         if (result && !error) {
             NSString *pageHtml = [[NSString alloc] initWithData:result encoding:NSWindowsCP1251StringEncoding];
             if ([pageHtml rangeOfString:STRING_LOGIN_SUCCESS].location != NSNotFound) {
                 //TODO parse login normaly
                 _login = inputLogin;
                 isError = NO;
                 [self parseMainPage:block];
             } else if ([pageHtml rangeOfString:STRING_BAD_PASSWORD].location != NSNotFound) {
                 errorMsg = @"Неправильный пароль";
             } else if ([pageHtml rangeOfString:STRING_BAD_CAPTCHA].location != NSNotFound) {
                 errorMsg = @"Неправильно введена капча";
             } else if ([pageHtml rangeOfString:STRING_BANNDED].location != NSNotFound) {
                 errorMsg = @"Первышено макс. кол-во попыток входа";
             } else {
                 errorMsg = @"Неизвестная ошибка";
             }
         }
         if (isError) {
             block(YES, errorMsg);
         }
    }];
    
}

-(void)getChatContent:(void (^)(NSArray* newMessages, BOOL isError, NSString* errorMsg))block
{
    if (_authStatus != asLoggedIn) {
        block(nil, YES, @"Очень плохая ошибка, если вы ее видите, значит разработчик где-то накосячил");
        return;
    }
    [ZTRequester doPostRequest:API_GET_CHAT jsonAns:NO params:@{
                                                                   @"s":@"",
                                                                   @"securitytoken":securityToken
                                                                   }
    block:^(id result, NSError *error) {
        if (result && !error) {
            NSString *pageHtml = [[NSString alloc] initWithData:result encoding:NSWindowsCP1251StringEncoding];
            if ([pageHtml rangeOfString:STRING_NOT_CHAT].location != NSNotFound) {
                [self parseMainPage:^(BOOL isError, NSString *errorMsg) {
                    if (!isError) {
                        [self getChatContent:block];
                    } else {
                        block(nil, YES, @"Сессия истекла. Перелогиньтесь");
                    }
                }];
            } else {
                NSLog(@"%@",pageHtml);
                pageHtml = [ZTParser replaceSmiles:[ZTParser stringByDecodingXMLEntities:pageHtml]];
                NSArray* newMessages = [ZTParser parseMessages:pageHtml];
                if ([newMessages count] > 0) {
                    NSString* newLastMsgId = [[newMessages lastObject] valueForKey:@"msgId"];
                    if (![newLastMsgId isEqualToString:lastMsgId]) {
                        lastMsgId = newLastMsgId;
                        block(newMessages, NO, nil);
                    } else {
                        block(nil, NO, nil);
                    }
                } else {
                    block(nil, NO, nil);
                }
            }
        } else {
            block(nil, NO, nil);
        }
    }];
}

-(void)sendMsg:(NSString *)msg block:(void (^)(BOOL isError, NSString* errorMsg))block
{
    if (_authStatus != asLoggedIn) {
        block(YES, @"Очень плохая ошибка, если вы ее видите, значит разработчик где-то накосячил");
    }
    [ZTRequester doPostRequest:API_SEND_CHAT_MSG jsonAns:NO params:@{
                                                                @"s":@"",
                                                                @"securitytoken":securityToken,
                                                                @"do":@"cb_postnew",
                                                                @"ccb_newmessage":msg
                                                                }
     block:^(id result, NSError *error) {
         if (result && !error) {
             block(NO, nil);
         } else {
             block(YES, @"Не удалось отправить");
         }
     }];

}

@end
