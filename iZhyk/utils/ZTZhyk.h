#import <Foundation/Foundation.h>
@import UIKit;

typedef enum AuthStatus : NSUInteger {
    asLoggedOut,
    asBeforeCaptcha,
    asLoggedIn
} AuthStatus;

@interface ZTZhyk : NSObject

@property NSString *login;
@property AuthStatus authStatus;
@property BOOL chatAvailable;
@property NSString *userId;

-(UIColor *)loadMainColor;
-(void)saveMainColor:(UIColor *)mainColor;

-(void)authBeforeCaptchaWithLogin:(NSString *)login password:(NSString *)password block:(void (^)(NSString* imgUrl, BOOL isError, NSString* errorMsg))block;
-(void)reloadCaptchaImg:(void (^)(NSString* imgUrl, BOOL isError, NSString* errorMsg))block;
-(void)authAfterCaptcha:(NSString *)captchaText block:(void (^)(BOOL isError, NSString* errorMsg))block;
-(void)checkAuth:(void (^)(BOOL loggedIn, BOOL isError, NSString* errorMsg))block;
-(void)getChatContent:(void (^)(NSArray* newMessages, BOOL isError, NSString* errorMsg))block;
-(void)sendMsg:(NSString *)msg block:(void (^)(BOOL isError, NSString* errorMsg))block;
-(void)doLogout;

+(ZTZhyk *) sharedInstance;

// clue for improper use (produces compile time error)
+(instancetype) alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
-(instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));
+(instancetype) new __attribute__((unavailable("new not available, call sharedInstance instead")));

@end
