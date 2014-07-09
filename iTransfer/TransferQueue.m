//
//  TransferQueue.m
//  iTransfer
//
//  Created by Gavy Aggarwal on 10/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TransferQueue.h"

@implementation TransferQueue
@synthesize delegate;
@synthesize transferSession;
@synthesize transferPeers;
@synthesize displayQueue;
@synthesize fileQueue;
@synthesize isTransferring;

- (id)init
{
    self = [super init];
    if (self) {
        [self setDisplayQueue:[NSMutableArray array]];
        [self setFileQueue:[NSMutableArray array]];
        [self setIsTransferring:FALSE];
        // Initialization code here.
    }
    
    return self;
}

-(void)addFileToQueue:(NSString*)filePath withLabel:(NSString*)label {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *fileProperties = [fileManager attributesOfItemAtPath:filePath error:nil];
    int size = [fileProperties fileSize];
    
    NSLog(@"Size: %d", size);
    
    if(size>(5*1024*1024) && ![[NSUserDefaults standardUserDefaults] boolForKey:@"isSendBigFilesPurchased"]) {
        //if the file size is over 5 MB and the iAP is not purchased
        [[self delegate] transferQueueFileRemoved];
        return;
    }
    
    [self.fileQueue addObject:filePath];
    [self.displayQueue addObject:label];
    NSLog(@"File Added to Queue, Total Items: %d Transferring: %d", self.fileQueue.count, self.isTransferring);
    
    if([self isTransferring]!=TRUE) {
        //Begin Initial Transfer
        [self sendNextFile];
    }
    [[self delegate] transferQueueUpdated:YES];
}

-(void)sendNextFile {
    [self setIsTransferring:TRUE];
    //NSString *fileExtension = [[self.fileQueue objectAtIndex:0] substringFromIndex:[[self.fileQueue objectAtIndex:0] length]-3];
    NSString *fileNameUnformatted = [[self.fileQueue objectAtIndex:0] lastPathComponent];
    NSMutableString *fileNameFormatted = [NSMutableString stringWithCapacity:fileNameUnformatted.length];
    
    NSScanner *scanner = [NSScanner scannerWithString:fileNameUnformatted];
    NSMutableCharacterSet *allowedCharacters = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [allowedCharacters addCharactersInString:@". "];
    
    while ([scanner isAtEnd] == FALSE) {
        NSString *buffer;
        if ([scanner scanCharactersFromSet:allowedCharacters intoString:&buffer]) {
            [fileNameFormatted appendString:buffer];     
        } else {
            [scanner setScanLocation:([scanner scanLocation] + 1)];
        }
    }
    [allowedCharacters release];
    NSLog(@"File Name Formatted (\"%@\" -> \"%@\")", fileNameUnformatted, fileNameFormatted);
    NSData *data = [NSData dataWithContentsOfFile:(NSString *)[self.fileQueue objectAtIndex:0]];
    
    NSData *fileInfo = [[NSString stringWithFormat:@"1:%@:%d", fileNameFormatted, [data length]/1024+1] dataUsingEncoding: NSASCIIStringEncoding];
    
    [self sendData:fileInfo];
    [self sendData:data];
}

-(void)addPlaceHolderToQueue {
    [self.displayQueue addObject:@"Processing..."];
    [[self delegate] transferQueueUpdated:YES];
}

-(void)removePlaceHolderFromQueue {
    for (int i=0; i<self.displayQueue.count; i++) {
        if([[self.displayQueue objectAtIndex:i] isEqualToString:@"Processing..."]) {
            [self.displayQueue removeObjectAtIndex:i];
            break;
        }
    }
    [[self delegate] transferQueueUpdated:YES];
}

-(void)sendData:(NSData*)data {
    NSUInteger length = [data length];
    NSUInteger chunkSize = 1024;   //1 kilobyte
    NSUInteger offset = 0;
    do {
        NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
        NSData* chunk = [NSData dataWithBytesNoCopy:(void*)[data bytes] + offset length:thisChunkSize freeWhenDone:NO];
        offset += thisChunkSize;
        
        [transferSession sendData: chunk toPeers:transferPeers withDataMode:GKSendDataReliable error:nil];
        
    } while (offset < length);
    NSLog(@"Sent Data: %d bytes", data.length);
}

-(void)removeFileFromQueue:(NSString*)fileName {
    NSLog(@"Removing File from Queue");
    [self.displayQueue removeObjectAtIndex:0];
    [self.fileQueue removeObjectAtIndex:0];
    [self.delegate transferQueueUpdated:YES];
    
    NSLog(@"Queue (%d) Status: %@", self.fileQueue.count, self.fileQueue);
    if(self.fileQueue.count>0) {
        //There are still some files in the queue
        [self sendNextFile];
    } else {
        [self setIsTransferring:FALSE];
    }
}

@end
