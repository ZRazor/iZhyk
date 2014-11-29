//
//  ZTParser.h
//  iZhyk
//
//  Created by ZRazor on 24.11.14.
//  Copyright (c) 2014 Farpost. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZTParser : NSObject

+(NSString *)parseCaptchaHash:(NSString *)html;
+(NSString *)parseHumanVerifyHash:(NSString *)html;
+(NSString *)parseCaptchaImgHash:(NSString *)html;
+(NSString *)parseCaptchaImgHashAfterReload:(NSString *)html;
+(NSString *)parseSecurityToken:(NSString *)html;
+(NSString *)parseUserId:(NSString *)html;
+(NSString *)parseUserLogin:(NSString *)html;
+(NSArray *)parseMessages:(NSString *)html;
+(NSString *)replaceSmiles:(NSString *)html;
+(NSString *)stringByDecodingXMLEntities:(NSString *)input;

@end
