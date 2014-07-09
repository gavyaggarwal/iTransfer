//
//  FileViewer.h
//  iTransfer
//
//  Created by Gavy Aggarwal on 9/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DirectoryWatcher.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "WebServer.h"

@protocol FileListControllerDelegate <NSObject>
@required
-(void)fileSelectedWithPath:(NSString *)path;
-(void)fileListCancelled;
@end

@interface FileListController : UIViewController <UITableViewDelegate, UITableViewDataSource, DirectoryWatcherDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, WebServerDelegate, UIAlertViewDelegate> {
    id <FileListControllerDelegate> delegate;
    NSMutableArray *files;
    UITableView *fileTable;
    DirectoryWatcher *directoryWatcher;
}

@property (retain) id delegate;
@property (retain) NSMutableArray* files;
@property (nonatomic, retain) IBOutlet UITableView *fileTable;
@property (retain) DirectoryWatcher *directoryWatcher;
@property (retain) NSString *directory;
@property (retain) WebServer *webServer;

- (void) reloadFiles;
- (void) showActionSheet;
- (UIImage *) getIconForFileAtPath:(NSString *)path;
- (void) enableServer;

@end
