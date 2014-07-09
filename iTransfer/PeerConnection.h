//
//  PeerConnection.h
//  iTransfer
//
//  Created by Gavy Aggarwal on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "TransferFile.h"
#import "Timer.h"
#import <dispatch/dispatch.h>
#import "TransferList.h"

@protocol PeerConnectionDelegate <NSObject>
@required
- (void) queueUpdated:(int)items;
- (void) fileReceived;
- (void) peerStateChanged:(GKPeerConnectionState)state;
@optional
- (void) fileProgressUpdated;
- (void) transferErrorOccured:(int)error;
- (void) fileSending;
- (void) peerDeviceFamilyDetermined:(NSString *)family;
@end

@interface PeerConnection : NSObject <GKSessionDelegate, TransferListDelegate> {
    id <PeerConnectionDelegate> delegate;
    BOOL isConnected;
    GKSession *session;
    NSString *peerName;
    NSMutableArray *peers;
    NSInteger packetsTotal;
    NSInteger packetsReceived;
    NSFileHandle *fileHandle;
    Timer *timer;
    dispatch_queue_t transferQueue;
}

@property (retain) id delegate;
@property (assign) BOOL isConnected;
@property (assign) BOOL isSending;
@property (retain) GKSession *session;
@property (retain) NSString *peerName;
@property (retain) NSMutableArray *peers;
@property (assign) NSInteger packetsTotal;
@property (assign) NSInteger packetsReceived;
@property (retain) NSFileHandle *fileHandle;
@property (retain) Timer *timer;
@property (retain) TransferList *transferList;

- (void) reset;
- (void) processMessage:(NSData *)data;
- (void) appendData:(NSData *)data;
- (void) processQueue;
- (void) sendFile:(NSString *)filePath;
- (void) sendMessage:(NSString *)message;

typedef enum {
    PeerConnectionMessageTypeFileComing = 1,
    PeerConnectionMessageTypeFileReceived = 2,
    PeerConnectionMessageTypeAppVersion = 3
} PeerConnectionMessageType;

@end