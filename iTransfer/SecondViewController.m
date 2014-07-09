#import "SecondViewController.h"
#import "Reachability.h"

#define MIN_OPENS_FOR_REVIEW 5
#define MIN_TRANSFERS_FOR_REVIEW 10

@implementation SecondViewController

@synthesize tbView = _tbView;
@synthesize connection = _connection;
@synthesize popover = _popover;
@synthesize exporter = _exporter;
@synthesize purchasePrompt = _purchasePrompt;

- (void) viewDidLoad {
    NSLog(@"SecondViewController viewDidLoad Called");
    [super viewDidLoad];
    transferQueue = dispatch_queue_create("com.aggarwalcreations.itransfer.transfer_queue", NULL);
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"isSendBigFilesPurchased"]) {
        NSLog(@"Full Version Not Purchased");
        UIBarButtonItem *upgradeButton = [[UIBarButtonItem alloc] initWithTitle:@"Upgrade" style:UIBarButtonItemStylePlain target:self action:@selector(removeFileLimit)];
        self.navigationItem.rightBarButtonItem = upgradeButton;
        [upgradeButton release];
    }
    self.view.backgroundColor = [UIColor clearColor];
    Exporter *e = [[Exporter alloc] init];
    [e setDelegate:self];
    [e setTransferQueue:transferQueue];
    [self setExporter:e];
    [e release];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showPicker)];
    tapGesture.numberOfTapsRequired = 1;
    [self.disconnectedView addGestureRecognizer:tapGesture];
    [tapGesture release];
    
    [self reload];
    
    /*
     //Uncomment to create default images
    self.title = @"";
    self.navigationItem.rightBarButtonItem = nil;
    [self.disconnectedView removeFromSuperview];
    self.tabBarController.viewControllers = nil;
     */
    
    /*
     KNOWN ISSUE
     Base 64 Decoding (and Encoding?) is being a little funky on iOS 7 and causing some issues with file names
     */
}

/*- (void) viewDidLayoutSubviews {
    NSLog(@"Subviews Ready %f", self.spacer.frame.size.height);
    [UIView animateWithDuration:1.0 animations:^{
        self.spacerTop.constant = 59;
    }];
}*/

- (void) viewDidUnload {
    NSLog(@"SecondViewController viewDidUnload Called");
    dispatch_release(transferQueue);
    [self setTbView:nil];
    [self setConnection:nil];
    [self setPopover:nil];
    [self setExporter:nil];
    [self setPurchasePrompt:nil];
    [self setDisconnectedView:nil];
    [self setHud:nil];
    [super viewDidUnload];
}

- (void) dealloc {
    NSLog(@"SecondViewController dealloc Called");
    [_tbView release];
    [_connection release];
    [_popover release];
    [_exporter release];
    [_purchasePrompt release];
    [_disconnectedView release];
    [_hud release];
    [_spacerTop release];
    [_spacerBottom release];
    [_spacer release];
    [super dealloc];
}

#pragma mark -
#pragma mark PeerConnectionDelegate

- (void) peerStateChanged:(GKPeerConnectionState)state {
    [self reload];
}

- (void) fileProgressUpdated {
    [[self tbView] reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) fileReceived {
    [[self tbView] reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationMiddle];
}

- (void) transferErrorOccured:(int)error {
    if (error==0) {  //User does not have iAP purchased
        NSLog(@"Prompting User to Purchase \"Send Big Files\"");
        if (self.purchasePrompt==nil) {
            NSLog(@"Creating new purchase prompt");
            UIAlertView *a = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PURCHASE_PROMPT_TITLE", nil)
                                                        message:NSLocalizedString(@"PURCHASE_PROMPT_MESSAGE", nil)
                                                       delegate:self
                                              cancelButtonTitle:@"Later"
                                              otherButtonTitles:@"OK", nil];
            [a setTag:102];
            self.purchasePrompt = a;
            [a release];
        }
        [self.purchasePrompt show];
    }
}

- (void) queueUpdated:(int)items {
    //[self.tbView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    [self.tbView reloadData];
    if (items==0) {
        [[self tabBarItem] setBadgeValue:nil];
    } else {
        [[self tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%d", items]];
    }
}

- (void) fileSending {
    //PeerConnection is Sending File (let's ask the user to leave a review if he's an avid user)
    //Check for internet connection, files sent over 10, app opened over 5, and review not already left
    
    Reachability *reachability = [[Reachability reachabilityWithHostName: @"www.feistapps.com"] retain];
	//Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    
    //NSLog(@"info beyotch: %d %d %d", [[[NSUserDefaults standardUserDefaults] objectForKey:@"app_opens"] intValue], [[[NSUserDefaults standardUserDefaults] objectForKey:@"files_transferred"] intValue], [[[NSUserDefaults standardUserDefaults] objectForKey:@"left_review"] boolValue]);
    
    if (([[[NSUserDefaults standardUserDefaults] objectForKey:@"app_opens"] intValue] > MIN_OPENS_FOR_REVIEW) &&
        ([[[NSUserDefaults standardUserDefaults] objectForKey:@"files_transferred"] intValue] > MIN_TRANSFERS_FOR_REVIEW) &&
        ([[[NSUserDefaults standardUserDefaults] objectForKey:@"left_review"] boolValue] != YES) &&
        (networkStatus == ReachableViaWiFi || networkStatus == ReachableViaWWAN)) {
        NSLog(@"Prompting to Leave Review");
        UIAlertView *reviewPrompt = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"REVIEW_PROMPT_TITLE", nil)
                                                               message: NSLocalizedString(@"REVIEW_PROMPT_MESSAGE", nil)
                                                              delegate: self
                                                     cancelButtonTitle:@"No Thanks"
                                                     otherButtonTitles:@"Okay", nil];
        [reviewPrompt setTag:104];
        [reviewPrompt show];
        [reviewPrompt release];
    }
}

- (void) peerDeviceFamilyDetermined:(NSString *)family {
    [self createDashboardWithPeerFamily:family];
}

#pragma mark -

- (void) showPicker {
    GKPeerPickerController *peerPicker = [[GKPeerPickerController alloc] init];
    [peerPicker setDelegate:self];
    [peerPicker show];
}

- (void) createDashboardWithPeerFamily:(NSString *)family {
    /*
    CGSize cs = [[self.layout objectForKey:@"hudContentSize"] CGSizeValue];
    [self.hud setContentSize:cs];
    [self.view addSubview:self.hud];*/
    
    UIImageView *icon = (UIImageView *)[self.hud viewWithTag:1];
    //UILabel *l1 = (UILabel *)[self.hud viewWithTag:2];  //The "Connected" label
    UILabel *l2 = (UILabel *)[self.hud viewWithTag:3];
    UIButton *b1 = (UIButton *)[self.hud viewWithTag:4];
    UIButton *b2 = (UIButton *)[self.hud viewWithTag:5];
    
    UIImageView *im1 = (UIImageView *)[self.hud viewWithTag:11];
    UIImageView *im2 = (UIImageView *)[self.hud viewWithTag:13];
    UIImageView *im3 = (UIImageView *)[self.hud viewWithTag:15];
    UIImageView *im4 = (UIImageView *)[self.hud viewWithTag:17];
    UILabel *text1 = (UILabel *)[self.hud viewWithTag:12];
    UILabel *text2 = (UILabel *)[self.hud viewWithTag:14];
    UILabel *text3 = (UILabel *)[self.hud viewWithTag:16];
    UILabel *text4 = (UILabel *)[self.hud viewWithTag:18];
    
    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sendFile:)];
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sendFile:)];
    UITapGestureRecognizer *tap3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sendFile:)];
    UITapGestureRecognizer *tap4 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sendFile:)];
    UITapGestureRecognizer *tap5 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sendFile:)];
    UITapGestureRecognizer *tap6 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sendFile:)];
    [im1 addGestureRecognizer:tap1];
    [im2 addGestureRecognizer:tap2];
    [im3 addGestureRecognizer:tap3];
    [text1 addGestureRecognizer:tap4];
    [text2 addGestureRecognizer:tap5];
    [text3 addGestureRecognizer:tap6];
    
    if(b1 && b2) {
        //Must be iPhone
        [b1 addTarget:self action:@selector(confirmDisconnect) forControlEvents:UIControlEventTouchUpInside];
        [b2 addTarget:self action:@selector(scrollDashboard) forControlEvents:UIControlEventTouchUpInside];
    } else if (im4 && text4) {
        //Must be iPad
        UITapGestureRecognizer *tap7 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(confirmDisconnect)];
        UITapGestureRecognizer *tap8 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(confirmDisconnect)];
        [im4 addGestureRecognizer:tap7];
        [text4 addGestureRecognizer:tap8];
        [self.hud setScrollEnabled:NO];
    }
    
    [l2 setText:self.connection.peerName];
    
    if (family!=nil && ![family isEqualToString:@"Unknown"]) {
        NSString *imageName = @"iPhone Image";   //default image
        if ([family isEqualToString:@"iPhone"]) {
            imageName=@"iPhone Image";
        } else if ([family isEqualToString:@"iPad"]) {
            imageName=@"iPad Image";
        } else if ([family isEqualToString:@"iPod"]) {
            imageName=@"iPod Image";
        }
        icon.image = [UIImage imageNamed:imageName];
    }
}

- (void) scrollDashboard {
    [UIView animateWithDuration:0.5 delay:0.0 options:0 animations:^{
        self.hud.contentOffset = CGPointMake(self.hud.frame.size.width, 0);
    } completion:nil];
}

- (void) sendFile:(UITapGestureRecognizer *)sender {
    if (self.connection.isConnected==NO) {
        NSLog(@"Attempted to Send File but No User Connected");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hmmmm..." message:@"How are you supposed to send a file if you aren't connected? Tap the frowny face on two devices to connect." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    UIView *theSuperview = self.hud; // whatever view contains your image views
    CGPoint touchPointInSuperview = [sender locationInView:theSuperview];
    UIView *touchedView = [theSuperview hitTest:touchPointInSuperview withEvent:nil];
    /*if ([touchedView isKindOfClass:[UIImageView class]]) {
        [((UIImageView *)touchedView) setHighlighted:YES];
    } else if ([touchedView isKindOfClass:[UILabel class]]) {
        [((UILabel *)touchedView) setHighlighted:YES];
    }*/
    [touchedView setAlpha:0.5];
    [UIView animateWithDuration:1.0 animations:^ {
        [touchedView setAlpha:1.0];
    }];
    if(touchedView.tag==11 || touchedView.tag==12) {
        //Send Photo
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        CFStringRef mTypes[2] = { kUTTypeImage, kUTTypeMovie };
        CFArrayRef mTypesArray = CFArrayCreate(CFAllocatorGetDefault(), (const void**)mTypes, 2, &kCFTypeArrayCallBacks);
        imagePicker.mediaTypes = (NSArray*)mTypesArray;
        CFRelease(mTypesArray);
        imagePicker.delegate = self.exporter;
        [self openViewWithViewController:imagePicker andFrame:touchedView.frame];
        [imagePicker release];
    } else if(touchedView.tag==13 || touchedView.tag==14) {
        //Send Music
        MPMediaPickerController *pickerController =	[[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeMusic];
        [pickerController.navigationController.navigationBar setTintColor:[UIColor blackColor]];
        pickerController.prompt = @"Choose Song to Transfer";
        pickerController.showsCloudItems = NO;
        pickerController.allowsPickingMultipleItems = YES;
        pickerController.delegate = self.exporter;
        [self openViewWithViewController:pickerController andFrame:touchedView.frame];
        [pickerController release];
    } else if(touchedView.tag==15 || touchedView.tag==16) {
        //Send File
        FileListController *fileList = [[FileListController alloc] init];
        [fileList setDelegate:self.exporter];
        UINavigationController *innerNav = [[UINavigationController alloc] initWithRootViewController:fileList];
        [self openViewWithViewController:innerNav andFrame:touchedView.frame];
        [innerNav release];
        [fileList release];
    }
}

#pragma mark -
#pragma mark UIViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark -
#pragma mark GKPeerPickerControllerDelegate

- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type {
	GKSession* session = [[GKSession alloc] initWithSessionID:@"com.aggarwalcreations.iTransfer" displayName:nil sessionMode:GKSessionModePeer];
    [session autorelease];
    return session;
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session {
    //Take ownership of the session
    [self.connection setSession:session];
    session.disconnectTimeout=2;
    [session setDelegate:self.connection];
    //Get rid of picker
	[picker setDelegate:nil];
    [picker dismiss];
    [picker release];
    
    float sysVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (sysVersion >= 7) {
        //Crude Workaround for iOS 7 because GKSessionDelegate doesn't call – session:peer:didChangeState:
        //More info here: http://meachware.blogspot.com/2013/10/gksession-didchangestate-delegate-not.html
        NSLog(@"Using Workaround to Make Connection Work in iOS 7");
        [self.connection session:session peer:peerID didChangeState:GKPeerStateConnected];
    }
}

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker {
    [picker setDelegate:nil];
    [picker release];
}

- (void) removeFileLimit {
    UIUserInterfaceIdiom device;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)]) {
        device = [[UIDevice currentDevice] userInterfaceIdiom];
    } else {
        device = UIUserInterfaceIdiomPhone;
    }
    UpgradeView *upgradeView = [[UpgradeView alloc] init];
    [upgradeView setDelegate:self];
    UINavigationController *innerNav = [[UINavigationController alloc] initWithRootViewController:upgradeView];
    if (device==UIUserInterfaceIdiomPad) {
        if (self.popover!=nil) {
            [self closeView];
        }
        UIPopoverController *p = [[UIPopoverController alloc] initWithContentViewController:innerNav];
        [p setPopoverContentSize:CGSizeMake(320, 480)];
        [p setDelegate:self];
        [self setPopover:p];
        [p release];
        [self.popover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:innerNav animated:YES completion:nil];
        //[self presentModalViewController:innerNav animated:YES];
    }
    [innerNav release];
    [upgradeView release];
}

- (void) upgradeViewDismissed {
    [self closeView];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isSendBigFilesPurchased"]) {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void) reload {
    NSLog(@"SecondViewController reload Called");
    [self setConnection:[(iTransferAppDelegate *)[UIApplication sharedApplication].delegate connection]];
    [self.connection setDelegate:self];
    [self.tbView setDataSource:self.connection.transferList];
    [self.exporter setTransferList:self.connection.transferList];
    
    if (self.connection.isConnected==YES) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        float offset = self.spacer.frame.size.height;
        [UIView animateWithDuration:1.0 animations:^{
            self.spacerTop.constant = -offset;
            self.spacerBottom.constant = offset;
            [self.view layoutIfNeeded];
        }];
        [self createDashboardWithPeerFamily:nil];
    } else {
        [self.connection reset];
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        [UIView animateWithDuration:1.0 animations:^{
            self.spacerTop.constant = 0;
            self.spacerBottom.constant = 0;
            [self.view layoutIfNeeded];
        }];
    }
    int items = self.connection.transferList.outgoingFiles.count;
    if (items==0) {
        [[self tabBarItem] setBadgeValue:nil];
    } else {
        [[self tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%d", items]];
    }
    
    [[self tbView] reloadData];
}

- (void) openViewWithViewController:(UIViewController *)vc andFrame:(CGRect)f {
    UIUserInterfaceIdiom device;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)]) {
        device = [[UIDevice currentDevice] userInterfaceIdiom];
    } else {
        device = UIUserInterfaceIdiomPhone;
    }
    if (device==UIUserInterfaceIdiomPad) {
        if (self.popover==nil) {
            UIPopoverController *p = [[UIPopoverController alloc] initWithContentViewController:vc];
            [p setDelegate:self];
            [p setPopoverContentSize:CGSizeMake(320, 480)];
            [self setPopover:p];
            [p release];
            [self.popover presentPopoverFromRect:f inView:[self.hud viewWithTag:6] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
        }
    } else {
        //[self presentModalViewController:vc animated:YES];
        [self presentViewController:vc animated:YES completion:nil];
    }
}

- (void) closeView {
    UIUserInterfaceIdiom device;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)]) {
        device = [[UIDevice currentDevice] userInterfaceIdiom];
    } else {
        device = UIUserInterfaceIdiomPhone;
    }
    if (device==UIUserInterfaceIdiomPad) {
        [self.popover dismissPopoverAnimated:YES];
        [self setPopover:nil];
    } else {
        //[self dismissModalViewControllerAnimated:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self setPopover:nil];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    float offset = 0;
    if (self.connection.isConnected) {
        offset = self.spacer.frame.size.height;
    }
    [UIView animateWithDuration:duration animations:^{
        self.spacerTop.constant = -offset;
        self.spacerBottom.constant = offset;
        [self.view layoutIfNeeded];
    }];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    //[self createDashboardWithPeerFamily:nil];
    
    float offset = 0;
    if (self.connection.isConnected) {
        offset = self.spacer.frame.size.height;
    }
    NSLog(@"Offset %f", offset);
    self.spacerTop.constant = -offset;
    self.spacerBottom.constant = offset;
    [self.view layoutIfNeeded];
}

- (void) confirmDisconnect {
    if (self.connection.isSending || self.connection.transferList.incomingFile!=nil) {
        //File Transfer is in progess (confirm disconnecting)
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Disconnect from Peer?" message:@"If you disconnect now, the files currently being transferred will be aborted. Are you sure you want to disconnect?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [alert setTag:103];
        [alert show];
        [alert release];
    } else {
        [self.connection.session disconnectFromAllPeers];
    }
}

#pragma mark -
#pragma mark ExporterDelegate

- (void) exporterStateChangedDidCancel:(BOOL)canceled {
    NSLog(@"Exporter State Changed");
    [self closeView];
}

#pragma mark -
#pragma mark TransferListDelegate

- (void) fileStatusUpdated {
    [self.tbView reloadData];
}

#pragma mark -
#pragma UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *label = [self.tbView cellForRowAtIndexPath:indexPath].detailTextLabel.text;
    
    if ([label isEqualToString:NSLocalizedString(@"MUSIC_NOT_FOUND_LABEL", nil)]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"MUSIC_NOT_FOUND_TITLE", nil) message:NSLocalizedString(@"MUSIC_NOT_FOUND_MESSAGE", nil) delegate:self cancelButtonTitle:@"Ignore" otherButtonTitles:@"Clear", nil];
        alert.tag = 105;
        [alert show];
        [alert release];
    } else if ([label isEqualToString:NSLocalizedString(@"EXPORT_FAILURE_LABEL", nil)]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"EXPORT_FAILURE_TITLE", nil) message:NSLocalizedString(@"EXPORT_FAILURE_MESSAGE", nil) delegate:self cancelButtonTitle:@"Ignore" otherButtonTitles:@"Clear", nil];
        alert.tag = 105;
        [alert show];
        [alert release];
    } else if ([label isEqualToString:NSLocalizedString(@"PURCHASE_PROMPT_LABEL", nil)]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PURCHASE_PROMPT_TITLE", nil) message:NSLocalizedString(@"PURCHASE_PROMPT_MESSAGE", nil) delegate:self cancelButtonTitle:@"Later" otherButtonTitles:@"OK", nil];
        alert.tag = 102;
        [alert show];
        [alert release];
    }
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag==102) {   //User wants to upgrade app
        if (buttonIndex==1) {
            [self removeFileLimit];
        }
    } else if (alertView.tag==103) {   //User wants to terminate connection
        if (buttonIndex==1) {
            [self.connection.session disconnectFromAllPeers];
        }
    } else if (alertView.tag==104) {   //User wants to leave a review
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"left_review"];
        if (buttonIndex==1) {
            NSURL *reviewURL = [NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=480195086"];
            if ([[UIApplication sharedApplication] canOpenURL:reviewURL]) {
                [[UIApplication sharedApplication] openURL:reviewURL];
            }
        }
    } else if (alertView.tag==105) {
        if (buttonIndex==1) {
            dispatch_async(transferQueue, ^(void) {
                [self.connection.transferList cleanList];
            });
        }
    }
}

@end