//
//  BackgroundManager.m
//  iTransfer
//
//  Created by Gavy Aggarwal on 7/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BackgroundManager.h"
#import "iTransferAppDelegate.h"

@implementation BackgroundManager

@synthesize backgroundTask = _backgroundTask;
@synthesize statusTimer = _statusTimer;
@synthesize timeoutTimer = _timeoutTimer;
@synthesize connection = _connection;
@synthesize displayedMinuteNotification = _displayedMinuteNotification;
@synthesize lastConnectionStatus = _lastConnectionStatus;

+ (BOOL) canMultitask {
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && 
        [[UIDevice currentDevice] isMultitaskingSupported]) {
        return YES;
    }
    return NO;
}

- (id) init {
    NSLog(@"BackgroundManager init Called");
    self = [super init];
    if (self!=nil) {
        [self setConnection:[(iTransferAppDelegate *)[UIApplication sharedApplication].delegate connection]];
        [self.connection setDelegate:self];
    }
    return self;
}

- (void) start {
    NSLog(@"BackgroundManager start Called");
    [self setBackgroundTask:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^ {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask]; //Tell the system that we are done with the tasks
        self.backgroundTask = UIBackgroundTaskInvalid; //Set the task to be invalid (OS kills app)
    }]];
    [self setLastConnectionStatus:YES];
    [self checkStatus];
    [self checkTimeout];
    //return [self backgroundTask];
}

- (void) end {
    NSLog(@"BackgroundManager end Called");
    [[self statusTimer] invalidate];
    [[self timeoutTimer] invalidate];
    //[[[self connection] session] disconnectFromAllPeers];
    [[UIApplication sharedApplication] endBackgroundTask: self.backgroundTask]; //End the task so the system knows that you are done with what you need to perform
    [self setBackgroundTask:UIBackgroundTaskInvalid]; //Invalidate the background_task
}

- (void) checkStatus {
    float timeLeft = UIApplication.sharedApplication.backgroundTimeRemaining;
    NSLog(@"BackgroundManager checkStatus Called (Background Time Left: %f)", timeLeft);
    if (timeLeft>5.1) {
        [self setStatusTimer:[NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(checkStatus) userInfo:nil repeats:NO]];
    } else {
        [self setStatusTimer:[NSTimer scheduledTimerWithTimeInterval:timeLeft-0.1 target:self selector:@selector(end) userInfo:nil repeats:NO]];
    }
    if (timeLeft<60.0 && self.displayedMinuteNotification==NO && (self.connection.isSending || self.connection.transferList.incomingFile!=nil)) {
        NSLog(@"Sent User Notification");
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        [notification setFireDate:[NSDate date]];
        [notification setTimeZone:[NSTimeZone defaultTimeZone]];
        [notification setSoundName:UILocalNotificationDefaultSoundName];
        [notification setAlertBody:NSLocalizedString(@"USER_BACKGROUND_NOTIFICATION_ONE_MINUTE_BODY", nil)];
        [notification setAlertAction:NSLocalizedString(@"USER_BACKGROUND_NOTIFICATION_ONE_MINUTE_ACTION", nil)];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        [notification release];
        [self setDisplayedMinuteNotification:YES];
    }
}

- (void) checkTimeout {
    NSLog(@"BackgroundManager checkTimeout Called");
    if (self.connection.isSending || self.connection.transferList.incomingFile!=nil) {
        [self setLastConnectionStatus:YES];
        [self setTimeoutTimer:[NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(checkTimeout) userInfo:nil repeats:NO]];
    } else {
        if ([self lastConnectionStatus]==NO) {
            [self end];
        } else {
            [self setLastConnectionStatus:NO];
            [self setTimeoutTimer:[NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(checkTimeout) userInfo:nil repeats:NO]];
        }
    }
}

- (void) dealloc {
    NSLog(@"BackgroundManager dealloc Called");
    [_statusTimer release];
    [_timeoutTimer release];
    [_connection release];
    [super dealloc];
}

#pragma mark -
#pragma mark PeerConnectionDelegate

- (void) queueUpdated:(int)items {
    NSLog(@"Queue Updated (in background)");
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:items];
}

- (void) peerStateChanged:(GKPeerConnectionState)state {
    if (state==GKPeerStateDisconnected) {
        [self end];
    }
}

- (void) fileReceived {
    NSLog(@"File Received (in background)");
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[UIApplication sharedApplication] applicationIconBadgeNumber]+1];
}

@end