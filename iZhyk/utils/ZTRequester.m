#import "ZTRequester.h"
#import <AFHTTPRequestOperationManager.h>

@implementation ZTRequester

+ (void)saveCookies
{
    
    NSData *cookiesData = [NSKeyedArchiver archivedDataWithRootObject: [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: cookiesData forKey: @"sessionCookies"];
    [defaults synchronize];
    
}

+ (void)loadCookies
{
    NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData: [[NSUserDefaults standardUserDefaults] objectForKey: @"sessionCookies"]];
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    for (NSHTTPCookie *cookie in cookies){
        [cookieStorage setCookie: cookie];
    }
    
}

+ (void)deleteCookies
{
    NSArray* cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie* cookie in cookies) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sessionCookies"];
}

+ (void)doPostRequest:(NSString *)url jsonAns:(BOOL)jsonAns params:(NSDictionary *)params block:(void (^)(id result, NSError *error))block
{
    [ZTRequester doRequest:url isBaseUrl:YES isPost:YES jsonAns:jsonAns params:params block:block];
}

+ (void)doGetRequest:(NSString *)url jsonAns:(BOOL)jsonAns params:(NSDictionary *)params block:(void (^)(id result, NSError *error))block
{
    [ZTRequester doRequest:url isBaseUrl:YES isPost:NO jsonAns:jsonAns params:params block:block];
}

+ (void)doRequest:(NSString *)url isBaseUrl:(BOOL)isBaseUrl isPost:(BOOL)isPost jsonAns:(BOOL)jsonAns params:(NSDictionary *)params block:(void (^)(id result, NSError *error))block
{
    NSString *requestUrl = url;
    if (isBaseUrl) {
        requestUrl = [NSString stringWithFormat:@"%@%@", API_BASE_URL, url];
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    if (jsonAns) {
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/plain", nil];
    } else {
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        if (isBaseUrl) {
            manager.requestSerializer.stringEncoding = NSWindowsCP1251StringEncoding;
        }
    }
    if (isPost) {
        [manager POST:requestUrl parameters:params
              success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             block(responseObject, nil);
         }
              failure:
         ^(AFHTTPRequestOperation *operation, NSError *error) {
             block(nil, error);
         }];
    } else {
        [manager GET:requestUrl parameters:params
              success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             [ZTRequester saveCookies];
             block(responseObject, nil);
         }
              failure:
         ^(AFHTTPRequestOperation *operation, NSError *error) {
             block(nil, error);
         }];
    }
    
}

@end
