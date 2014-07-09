//
//  iTransferAppDelegate.h
//  iTransfer
//
//  Created by Gavy Aggarwal on 9/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import <dispatch/dispatch.h>
#import "PeerConnection.h"
#import "UDID.h"
#import "SecondViewController.h"
#import "BackgroundManager.h"

@interface iTransferAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) PeerConnection *connection;
@property (nonatomic, retain) BackgroundManager *backgroundManager;

- (void) setTheme;
- (void) configureSettings;
@end