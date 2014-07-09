//
//  TransferQueue.h
//  iTransfer
//
//  Created by Gavy Aggarwal on 10/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@protocol TransferQueueDelegate <NSObject>
@required
-(void)transferQueueUpdated:(BOOL)success;
-(void)transferQueueFileRemoved;
@end

@interface TransferQueue : NSObject {
    id <TransferQueueDelegate> delegate;
    GKSession *transferSession;
    NSMutableArray *transferPeers;
    NSMutableArray *displayQueue;
    NSMutableArray *fileQueue;
    BOOL isTransferring;
}

@property (retain) id delegate;
@property (retain) GKSession *transferSession;
@property (retain) NSMutableArray *transferPeers;
@property (retain) NSMutableArray *displayQueue;
@property (retain) NSMutableArray *fileQueue;
@property (assign) BOOL isTransferring;


-(void)addFileToQueue:(NSString*)filePath withLabel:(NSString*)label;
-(void)addPlaceHolderToQueue;
-(void)removePlaceHolderFromQueue;
-(void)sendData:(NSData*)data;
-(void)removeFileFromQueue:(NSString*)fileName;
-(void)sendNextFile;

@end