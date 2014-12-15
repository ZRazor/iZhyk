//
//  ZTParser.m
//  iZhyk
//
//  Created by ZRazor on 24.11.14.
//  Copyright (c) 2014 Farpost. All rights reserved.
//

#import "ZTParser.h"
@import UIKit;

@implementation ZTParser


+(NSString *)parseFirstMatch:(NSString *)html pattern:(NSString *)pattern
{
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:pattern
                                  options:NSRegularExpressionDotMatchesLineSeparators
                                  error:nil];
    NSTextCheckingResult *textCheckingResult = [regex firstMatchInString:html options:0 range:NSMakeRange(0, html.length)];
    
    NSRange matchRange = [textCheckingResult rangeAtIndex:1];
    NSString *match = [html substringWithRange:matchRange];
    NSLog(@"Found string '%@'", match);
    return match;

}

+(NSArray *)parseAllMatch:(NSString *)html pattern:(NSString *)pattern
{
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:pattern
                                  options:NSRegularExpressionDotMatchesLineSeparators
                                  error:nil];
    NSArray *matches = [regex matchesInString:html options:0 range:NSMakeRange(0, html.length)];
    
    NSMutableArray *result = [NSMutableArray array];
    
    for (NSTextCheckingResult* check in matches) {
        NSRange matchRange = [check rangeAtIndex:1];
        NSString *match = [html substringWithRange:matchRange];
        [result addObject:match];
    }
    return result;
}

+(NSString *)parseCaptchaHash:(NSString *)html
{
    return [ZTParser parseFirstMatch:html pattern:@"challenge\\?k=(.*?)\""];
}

+(NSString *)parseHumanVerifyHash:(NSString *)html
{
    return [ZTParser parseFirstMatch:html pattern:@"humanverify.*?value=\"(.*?)\""];
}

+(NSString *)parseCaptchaImgHash:(NSString *)html
{
    return [ZTParser parseFirstMatch:html pattern:@"challenge : '(.*?)'"];
}

+(NSString *)parseCaptchaImgHashAfterReload:(NSString *)html
{
    return [ZTParser parseFirstMatch:html pattern:@"finish_reload\\('(.*?)'"];
}

+(NSString *)parseSecurityToken:(NSString *)html
{
    return [ZTParser parseFirstMatch:html pattern:@"SECURITYTOKEN = \"(.*?)\""];
}

+(NSString *)parseUserId:(NSString *)html
{
    return [ZTParser parseFirstMatch:html pattern:@"Добро пожаловать, <a href=\"member.*?=(.*?)\""];
}

+(NSString *)parseUserLogin:(NSString *)html
{
    return [ZTParser parseFirstMatch:html pattern:@"Добро пожаловать, <a href=\"member.*?>(.*?)</a>"];
}

+(NSString *)convertToString:(NSString *)html
{
    NSScanner *myScanner;
    NSString *text = nil;
    myScanner = [NSScanner scannerWithString:html];
    
    while ([myScanner isAtEnd] == NO) {
        
        [myScanner scanUpToString:@"<" intoString:NULL] ;
        
        [myScanner scanUpToString:@">" intoString:&text] ;
        
        html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@""];
    }
    //
    html = [html stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return html;
}

+(NSString *)fixUrls:(NSString *)html
{
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"<a href=\"(.*?)\" target=\"_blank\">"
                                  options:NSRegularExpressionDotMatchesLineSeparators
                                  error:nil];
    NSString *result = [regex stringByReplacingMatchesInString:html options:0 range:NSMakeRange(0, html.length) withTemplate:@"$1<"];
    return result;
}

+(NSArray *)parseMessages:(NSString *)html
{
    NSMutableArray* result = [NSMutableArray array];
    @try {
        NSArray* texts = [ZTParser parseAllMatch:html pattern:@"<tr valign=.*?<td style=.*?>(.*?)</td>"];
        NSArray* authors = [ZTParser parseAllMatch:html pattern:@";<a href=\"member.php.*?>(.*?)</a>"];
        NSArray* authorIds = [ZTParser parseAllMatch:html pattern:@";<a href=\"member.php.*?=(.*?)\""];
        NSArray* msgIds = [ZTParser parseAllMatch:html pattern:@"misc.php\\?ccbloc=(.*?)\""];
        NSArray* times = [ZTParser parseAllMatch:html pattern:@" /> </a> \\[(.*?)\\]"];
        for (int i = 0; i < [texts count]; i++) {
            NSMutableDictionary* msg = [NSMutableDictionary dictionary];
            msg[@"text"] = [ZTParser fixUrls:texts[i]];
            msg[@"text"] = [ZTParser convertToString:msg[@"text"]];
            msg[@"author"] = [ZTParser convertToString:authors[i]];
            msg[@"authorId"] = authorIds[i];
            msg[@"msgId"] = msgIds[i];
            msg[@"time"] = times[i];
            [result addObject:msg];
        }
    }
    @catch (NSException *e) {
        
    }
    return result;
}

+(NSString *)replaceSmiles:(NSString *)html
{
    NSString* newHtml = [NSString stringWithString:html];
    NSMutableArray *smilesToReplace = [NSMutableArray array];
    [smilesToReplace addObject:@{
                                 @"tag":@"<img src=\"images/smilies/trololo/parrot2.gif\" border=\"0\" alt=\"\" title=\"Parrot\" class=\"inlineimg\" />",
                                 @"name":@"/bonk"
                                 }];
    [smilesToReplace addObject:@{
                                 @"tag":@"<img src=\"http://zhyk.ru/forum/images/smilies/crabe.png\" border=\"0\" alt=\"\" title=\"Crabe\" class=\"inlineimg\" />",
                                 @"name":@":crabe:"
                                 }];
    [smilesToReplace addObject:@{
                                 @"tag":@"<img src=\"images/smilies/trololo/poptartFINALTINY.gif\" border=\"0\" alt=\"\" title=\"nyaa\" class=\"inlineimg\" />",
                                 @"name":@"/nyan"
                                 }];
    [smilesToReplace addObject:@{
                                 @"tag":@"<img src=\"http://zhyk.ru/forum/images/smilies/w/emolol.gif\" border=\"0\" alt=\"\" title=\"Emolol\" class=\"inlineimg\" />",
                                 @"name":@":emobol:"
                                 }];
    [smilesToReplace addObject:@{
                                 @"tag":@"<img src=\"http://zhyk.ru/forum/images/smilies/z/cry.gif\" border=\"0\" alt=\"\" title=\"Cry\" class=\"inlineimg\" />",
                                 @"name":@":cry:"
                                 }];
    [smilesToReplace addObject:@{
                                 @"tag":@"<img src=\"http://zhyk.ru/forum/images/smilies/bayan.gif\" border=\"0\" alt=\"\" title=\"Bayan\" class=\"inlineimg\" />",
                                 @"name":@":bayan:"
                                 }];
    [smilesToReplace addObject:@{
                                 @"tag":@"<img src=\"images/smilies/trololo/fthat.png\" border=\"0\" alt=\"\" title=\"Не говори глупостей\" class=\"inlineimg\" />",
                                 @"name":@"/dgs"
                                 }];
    [smilesToReplace addObject:@{
                                 @"tag":@"<img src=\"images/smilies/trololo/okay.png\" border=\"0\" alt=\"\" title=\"okay\" class=\"inlineimg\" />",
                                 @"name":@"/okay"
                                 }];
    [smilesToReplace addObject:@{
                                 @"tag":@"<img src=\"http://zhyk.ru/forum/images/smilies/w/bow.gif\" border=\"0\" alt=\"\" title=\"Bow\" class=\"inlineimg\" />",
                                 @"name":@":bow:"
                                 }];
    [smilesToReplace addObject:@{
                                 @"tag":@"<img src=\"http://zhyk.ru/forum/images/smilies/x/bl.gif\" border=\"0\" alt=\"\" title=\"Bl\" class=\"inlineimg\" />",
                                 @"name":@":bl:"
                                 }];
    [smilesToReplace addObject:@{
                                 @"tag":@"<img src=\"http://zhyk.ru/forum/images/smilies/y/ban.gif\" border=\"0\" alt=\"\" title=\"Ban\" class=\"inlineimg\" /> ",
                                 @"name":@":ban:"
                                 }];
    [smilesToReplace addObject:@{
                                 @"tag":@"<img src=\"http://zhyk.ru/forum/images/smilies/y/gordon.gif\" border=\"0\" alt=\"\" title=\"Gordon\" class=\"inlineimg\" />",
                                 @"name":@":godron:"
                                 }];
    [smilesToReplace addObject:@{
                                 @"tag":@"<img src=\"images/smilies/trololo/drhouse.gif\" border=\"0\" alt=\"\" title=\"Drhouse\" class=\"inlineimg\" />",
                                 @"name":@"/md"
                                 }];
    [smilesToReplace addObject:@{
                                 @"tag":@"<img src=\"images/smilies/trololo/elefant.gif\" border=\"0\" alt=\"\" title=\"Elefant\" class=\"inlineimg\" />",
                                 @"name":@":elefant:"
                                 }];
    [smilesToReplace addObject:@{
                                 @"tag":@"<img src=\"http://zhyk.ru/forum/images/smilies/y/pandal.gif\" border=\"0\" alt=\"\" title=\"Pandal\" class=\"inlineimg\" />",
                                 @"name":@":pandal:"
                                 }];
    [smilesToReplace addObject:@{
                                 @"tag":@"<img src=\"http://zhyk.ru/forum/images/smilies/biggrin.gif\" border=\"0\" alt=\"\" title=\"Big Grin\" class=\"inlineimg\" />",
                                 @"name":@":D"
                                 }];
    for (NSDictionary* dict in smilesToReplace) {
        newHtml = [newHtml stringByReplacingOccurrencesOfString:dict[@"tag"] withString:dict[@"name"]];
    }
    return newHtml;
}

+ (NSString *)stringByDecodingXMLEntities:(NSString *)input {
    NSUInteger myLength = [input length];
    NSUInteger ampIndex = [input rangeOfString:@"&" options:NSLiteralSearch].location;
    
    // Short-circuit if there are no ampersands.
    if (ampIndex == NSNotFound) {
        return input;
    }
    // Make result string with some extra capacity.
    NSMutableString *result = [NSMutableString stringWithCapacity:(myLength * 1.25)];
    
    // First iteration doesn't need to scan to & since we did that already, but for code simplicity's sake we'll do it again with the scanner.
    NSScanner *scanner = [NSScanner scannerWithString:input];
    
    [scanner setCharactersToBeSkipped:nil];
    
    NSCharacterSet *boundaryCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" \t\n\r;"];
    
    do {
        // Scan up to the next entity or the end of the string.
        NSString *nonEntityString;
        if ([scanner scanUpToString:@"&" intoString:&nonEntityString]) {
            [result appendString:nonEntityString];
        }
        if ([scanner isAtEnd]) {
            goto finish;
        }
        // Scan either a HTML or numeric character entity reference.
        if ([scanner scanString:@"&amp;" intoString:NULL])
            [result appendString:@"&"];
        else if ([scanner scanString:@"&apos;" intoString:NULL])
            [result appendString:@"'"];
        else if ([scanner scanString:@"&quot;" intoString:NULL])
            [result appendString:@"\""];
        else if ([scanner scanString:@"&lt;" intoString:NULL])
            [result appendString:@"<"];
        else if ([scanner scanString:@"&gt;" intoString:NULL])
            [result appendString:@">"];
        else if ([scanner scanString:@"&#" intoString:NULL]) {
            BOOL gotNumber;
            unsigned charCode;
            NSString *xForHex = @"";
            
            // Is it hex or decimal?
            if ([scanner scanString:@"x" intoString:&xForHex]) {
                gotNumber = [scanner scanHexInt:&charCode];
            }
            else {
                gotNumber = [scanner scanInt:(int*)&charCode];
            }
            
            if (gotNumber) {
                [result appendFormat:@"%C", (unichar)charCode];
                
                [scanner scanString:@";" intoString:NULL];
            }
            else {
                NSString *unknownEntity = @"";
                
                [scanner scanUpToCharactersFromSet:boundaryCharacterSet intoString:&unknownEntity];
                
                
                [result appendFormat:@"&#%@%@", xForHex, unknownEntity];
                
                //[scanner scanUpToString:@";" intoString:&unknownEntity];
                //[result appendFormat:@"&#%@%@;", xForHex, unknownEntity];
                NSLog(@"Expected numeric character entity but got &#%@%@;", xForHex, unknownEntity);
                
            }
            
        }
        else {
            NSString *amp;
            
            [scanner scanString:@"&" intoString:&amp];  //an isolated & symbol
            [result appendString:amp];
            
            /*
             NSString *unknownEntity = @"";
             [scanner scanUpToString:@";" intoString:&unknownEntity];
             NSString *semicolon = @"";
             [scanner scanString:@";" intoString:&semicolon];
             [result appendFormat:@"%@%@", unknownEntity, semicolon];
             NSLog(@"Unsupported XML character entity %@%@", unknownEntity, semicolon);
             */
        }
        
    }
    while (![scanner isAtEnd]);
    
finish:
    return result;
}

@end
