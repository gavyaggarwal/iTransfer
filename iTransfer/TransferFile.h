//
//  TransferFile.h
//  iTransfer
//
//  Created by Gavy Aggarwal on 6/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TransferFile : NSObject {
    BOOL isReady;
    NSString *filePath;
    NSString *fileName;
    NSString *label;
}

@property (assign) BOOL isReady;
@property (retain) NSString *filePath;
@property (retain) NSString *fileName;
@property (retain) NSString *label;

- (id) initWithFilePath:(NSString *)fp fileName:(NSString *)fn label:(NSString *)l isReady:(BOOL)r;

@end