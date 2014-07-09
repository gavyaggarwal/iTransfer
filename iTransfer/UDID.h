//
//  Utilities.h
//  iTransfer
//
//  Created by Gavy Aggarwal on 6/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <CommonCrypto/CommonDigest.h>

@interface UDID : NSObject

+ (NSString *) getUDID;
+ (NSString *) getMAC;
+ (NSString *) getBundleID;
+ (NSString *) md5:(NSString *)string;
+ (NSString *) encodeBase64WithString:(NSString *)strData;
+ (NSData *) decodeBase64WithString:(NSString *)strBase64;
+ (NSString *) getPrivateIP;
+ (NSString *) getFormattedFileSize:(unsigned long long)value;
+ (NSString *) getDeviceModel;

@end
