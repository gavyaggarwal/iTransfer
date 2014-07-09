//
//  TransferFile.m
//  iTransfer
//
//  Created by Gavy Aggarwal on 6/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TransferFile.h"

@implementation TransferFile
@synthesize isReady = _isReady;
@synthesize filePath = _filePath;
@synthesize fileName = _fileName;
@synthesize label = _label;

- (id) init {
    NSLog(@"TransferFile init Called");
    self = [super init];
    return self;
}

- (id) initWithFilePath:(NSString *)fp fileName:(NSString *)fn label:(NSString *)l isReady:(BOOL)r {
    NSLog(@"TransferFile initWithFilePath Called");
    self = [super init];
    if (self) {
        self.filePath=fp;
        self.fileName=fn;
        self.label=l;
        self.isReady=r;
    }
    return self;
}

- (void) dealloc {
    NSLog(@"TransferFile dealloc Called");
    [_filePath release];
    [_fileName release];
    [_label release];
    [super dealloc];
}

@end
