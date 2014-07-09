//
//  iTransferAppDelegate.m
//  iTransfer
//
//  Created by Gavy Aggarwal on 9/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "iTransferAppDelegate.h"
#import "GAI.h"

@implementation iTransferAppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;
@synthesize connection = _connection;
@synthesize backgroundManager = _backgroundManager;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    // Add the tab bar controller's current view as a subview of the window
    NSLog(@"iTransfer Launched");
    PeerConnection *pc = [[PeerConnection alloc] init];
    [self setConnection:pc];
    [pc release];
    NSString *deviceID = [[NSUserDefaults standardUserDefaults] objectForKey:@"UDID"];
    NSInteger appOpens = [[[NSUserDefaults standardUserDefaults] objectForKey:@"app_opens"] intValue];
    NSInteger filesTransferred = [[[NSUserDefaults standardUserDefaults] objectForKey:@"files_transferred"] intValue];
    appOpens++;
    [[NSUserDefaults standardUserDefaults] setInteger:appOpens forKey:@"app_opens"];
    if (deviceID==nil) {
        NSLog(@"Saving UDID");
        deviceID = [UDID getUDID];
        [[NSUserDefaults standardUserDefaults] setObject:deviceID forKey:@"UDID"];
    }
    NSLog(@"UDID: %@, App Opens: %d, Files Transferred: %d", deviceID, appOpens, filesTransferred);
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self setTheme];
    [self configureSettings];
    
    if([[[NSUserDefaults standardUserDefaults] objectForKey:@"analytics"] boolValue]) {
        NSLog(@"Enabling Analytics");
        [GAI sharedInstance].trackUncaughtExceptions = YES;
        [GAI sharedInstance].dispatchInterval = 20;
        [GAI sharedInstance].debug = YES;
        id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:@"UA-42086533-1"];
    }

    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    // Make sure url indicates a file (as opposed to, e.g., http://)
    if (url != nil && [url isFileURL]) {
        NSLog(@"File (%@) Imported into iTransfer from %@", url.path, sourceApplication);
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *fileName           = url.path.lastPathComponent;
        NSString *fileExtension      = url.path.pathExtension;
        NSString *filePrefix         = [fileName substringToIndex:((fileName.length-fileExtension.length)-1)];
        NSString *finalPath          = [NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName];
        
        NSFileManager *fm = [[NSFileManager alloc] init];
        int i = 2;
        while ([fm fileExistsAtPath:finalPath]) {
            finalPath = [NSString stringWithFormat:@"%@/%@ (%d).%@", documentsDirectory, filePrefix, i, fileExtension];
            i++;
        }
        NSError *error = nil;
        if ([fm moveItemAtPath:url.path toPath:finalPath error:&error]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_IMPORTED_COMPLETED_ALERT_TITLE", nil)
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"FILE_IMPORTED_COMPLETED_ALERT_MESSAGE", nil), fileName]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"FILE_IMPORTED_COMPLETED_ALERT_CANCEL_BUTTON", nil)
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"FILE_IMPORTED_FAILED_ALERT_TITLE", nil)
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"FILE_IMPORTED_FAILED_ALERT_MESSAGE", nil), fileName, error.localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"FILE_IMPORTED_FAILED_ALERT_CANCEL_BUTTON", nil)
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
            
        }
        [fm release];
        UIViewController *vc = [[[self tabBarController] viewControllers] objectAtIndex:1];   //Received Files Page
        [[self tabBarController] setSelectedViewController:vc];
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    if ([[self connection] isConnected] && [BackgroundManager canMultitask]) {
        BackgroundManager *bm = [[BackgroundManager alloc] init];
        [self setBackgroundManager:bm];
        [bm release];
        [[self backgroundManager] start];
                
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
            [[self connection] setDelegate:[self backgroundManager]];
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:self.connection.transferList.outgoingFiles.count];
        });
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    if (self.backgroundManager!=nil) {
        [[self backgroundManager] end];
        [self setBackgroundManager:nil];
    }
    SecondViewController *vc = (SecondViewController *)((UINavigationController *)self.tabBarController.viewControllers.firstObject).viewControllers.firstObject;
    if (vc!=nil) {
        [vc reload];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc
{
    [_window release];
    [_tabBarController release];
    [_connection release];
    [_backgroundManager release];
    [super dealloc];
}

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
 */

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
 */

- (void) setTheme {
    NSLog(@"Setting Theme");
    //Customize the theme for iOS5 devices
    if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
        UIColor *greenColor = [UIColor colorWithRed:0.09 green:0.827 blue:0.588 alpha:1]; /*#17d396*/
        float sysVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        if (sysVersion >= 7) {
            NSLog(@"Enabling iOS 7 Theme");
            [[UINavigationBar appearance] setBarTintColor:greenColor];
            [[UINavigationBar appearance] setTintColor:UIColor.whiteColor];
            [[UITabBar appearance] setTintColor:greenColor];
            [[UIToolbar appearance] setTintColor:greenColor];
            [[UIButton appearance] setTintColor:greenColor];
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
        } else {
            [[UINavigationBar appearance] setTintColor:greenColor];
            [[UIToolbar appearance] setTintColor:greenColor];
            [[UITabBar appearance] setSelectedImageTintColor:greenColor];
        }
        [[UINavigationBar appearance] setTitleTextAttributes:@{UITextAttributeTextColor: UIColor.whiteColor}];
        if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) {
            [[UINavigationBar appearanceWhenContainedIn:[UIPopoverController class], nil] setTitleTextAttributes:nil];
        }
    }
}

- (void) configureSettings {
    NSLog(@"Configuring Settings");
    dispatch_queue_t settingsQueue = dispatch_queue_create("com.aggarwalcreations.itransfer.settings_queue", NULL);
    dispatch_async(settingsQueue, ^(void) {
        //Connect to server to verify settings
        if ((id)NSClassFromString(@"NSJSONSerialization")!=nil) {  //JSON processing is supported (workaround for old devices)
            //Get settings from server
            NSURL *settingsURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", NSLocalizedString(@"BASE_URL", nil), NSLocalizedString(@"SETTINGS_REMOTE_FILE_NAME", nil)]];
            NSError *error = nil;
            NSDictionary *dictionary = nil;
            NSData *JSON = [NSData dataWithContentsOfURL:settingsURL];
            if (JSON==nil) {
                NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                [errorDetail setValue:@"Cannot Connect to Server" forKey:NSLocalizedDescriptionKey];
                error = [NSError errorWithDomain:NSOSStatusErrorDomain code:444 userInfo:errorDetail];
            } else {
                dictionary = [(id)NSClassFromString(@"NSJSONSerialization") JSONObjectWithData:JSON options:kNilOptions error:&error];
            }
            if (dictionary!=nil) {
                //NSLog(@"%@", dictionary);
                BOOL isAvailable = [[dictionary valueForKey:@"availability"] boolValue];
                if (isAvailable) {
                    //Do stuff
                    NSNumber *analytics = [dictionary valueForKey:@"analytics"];
                    NSNumber *validation = [dictionary valueForKey:@"purchase_validation"];
                    //NSString *baseURL = [dictionary valueForKey:@"base_url"];
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [[NSUserDefaults standardUserDefaults] setObject:analytics forKey:@"analytics"];
                        [[NSUserDefaults standardUserDefaults] setObject:validation forKey:@"purchase_validation"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    });
                } else {
                    NSLog(@"Recieved Invalid Settings");
                }
            } else {
                NSLog(@"Error Receiving Settings: %@", error.description);
            }
        }
    });
    dispatch_release(settingsQueue);
}

@end
