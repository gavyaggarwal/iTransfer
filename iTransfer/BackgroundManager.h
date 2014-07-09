//
//  BackgroundManager.h
//  iTransfer
//
//  Created by Gavy Aggarwal on 7/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PeerConnection.h"

@interface BackgroundManager : NSObject <PeerConnectionDelegate>

@property (atomic) __block UIBackgroundTaskIdentifier backgroundTask;
@property (retain) NSTimer *statusTimer;
@property (retain) NSTimer *timeoutTimer;
@property (retain) PeerConnection *connection;
@property (assign) BOOL displayedMinuteNotification;
@property (assign) BOOL lastConnectionStatus;

+ (BOOL) canMultitask;
- (void) start;
- (void) end;
- (void) checkStatus;
- (void) checkTimeout;

@end