//
//  FileViewer.m
//  iTransfer
//
//  Created by Gavy Aggarwal on 9/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FileListController.h"
#import "FileViewerController.h"
#import "iTransferAppDelegate.h"
#import "UDID.h"
#import "Reachability.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

@implementation FileListController
@synthesize files, fileTable, delegate, directoryWatcher;
@synthesize directory = _directory;
@synthesize webServer = _webServer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithDirectoryPath:(NSString *)path {
    self = [super init];
    if (self) {
        [self setDirectory:path];
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSLog(@"FileListController viewDidLoad Called");
    
    if(self.delegate==nil && self.directory==nil) {
        UIBarButtonItem *serverButton = [[UIBarButtonItem alloc] initWithTitle:@"Server" style:UIBarButtonItemStyleBordered target:self action:@selector(enableServer)];
        [self.navigationItem setLeftBarButtonItem:serverButton];
        [serverButton release];
        
        WebServer *ws = [[WebServer alloc] init];
        [self setWebServer:ws];
        [self.webServer setDelegate:self];
        [ws release];
    }
    
    if (self.delegate) {
        NSLog(@"Delegate Found");
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:[self delegate] action:@selector(fileListCancelled)];
        self.navigationItem.rightBarButtonItem=cancelButton;
        [cancelButton release];
        //[self.navigationItem setPrompt:@"Choose File to Transfer"];
    } else {
        NSLog(@"No Delegate");
        [self.navigationItem setRightBarButtonItem:self.editButtonItem];
    }
    
    if (self.directory==nil) {
        //Use default directory
        [self setDirectory:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
        [self setTitle:@"Received Files"];
    } else {
        //Set title based on current directory
        [self setTitle:self.directory.lastPathComponent];
    }
    
    [self reloadFiles];
    
    [self setDirectoryWatcher:[DirectoryWatcher watchFolderWithPath:self.directory delegate:self]];
}

- (void)viewDidUnload {
    NSLog(@"FileListController viewDidUnload Called");
    [self setFiles:nil];
    [self setFileTable:nil];
    [self setDirectoryWatcher:nil];
    [self setDelegate:nil];
    [self setWebServer:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.files count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fileTable"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"fileTable"] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        if (self.delegate==nil) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        /*if ([UIImage instancesRespondToSelector:@selector(resizableImageWithCapInsets:)]) {
                UIEdgeInsets edgeInsets = UIEdgeInsetsMake(22, 75, 21, 74);
                UIImage *bgImage = [[UIImage imageNamed:@"cell-selection-middle.png"] resizableImageWithCapInsets:edgeInsets];
                UIView *bgView = [[UIImageView alloc] initWithImage:bgImage];
                [cell setSelectedBackgroundView:bgView];
                [bgView release];
        } else {
            [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
        }*/
    }
    cell.imageView.image = [self getIconForFileAtPath:[self.files objectAtIndex:indexPath.row]];
    cell.textLabel.text = [self.files objectAtIndex:[indexPath row]];
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self delegate]) {
        return UITableViewCellEditingStyleNone;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        if (tableView.indexPathsForSelectedRows.count==0) {
            self.navigationItem.rightBarButtonItem = self.editButtonItem;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"FileList Selected Row");
    if (tableView.isEditing) {
        if (tableView.indexPathsForSelectedRows.count>0) {
            UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(showActionSheet)];
            self.navigationItem.rightBarButtonItem = button;
            [button release];
        }
        //Don't do anything (wait to finish selecting)
        return;
    }
    NSString *selectedPath = [NSString stringWithFormat:@"%@/%@", self.directory, [self.files objectAtIndex:indexPath.row]];
    
    BOOL isDirectory = NO;
    BOOL fileExists = [[NSFileManager defaultManager]  fileExistsAtPath:selectedPath isDirectory:&isDirectory];
    if (fileExists && isDirectory) {
        //Open directory
        FileListController *fl = [[FileListController alloc] initWithDirectoryPath:selectedPath];
        [fl setDelegate:self.delegate];
        [self.navigationController pushViewController:fl animated:YES];
        [fl release];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if (fileExists) {
        if ([self delegate]) {
            //Tell Delegate File Has Been Selected
            [[self delegate] fileSelectedWithPath:selectedPath];
        } else {
            //Open File
            FileViewerController *fileViewer = [[FileViewerController alloc] initWithFilePath:selectedPath andIcon:[self getIconForFileAtPath:selectedPath]];
            [self.navigationController pushViewController:fileViewer animated:YES];
            [fileViewer release];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", self.directory, [self.files objectAtIndex:indexPath.row]] error:nil];
        //[self.fileTable deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing: editing animated: animated];
    [self.fileTable setEditing:editing animated:animated];
    if(editing==NO) {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
}

- (void)reloadFiles {
    NSLog(@"FileListController reloadFiles Called");
    NSArray *localFiles = [NSArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.directory error:nil]];
    self.files = (NSMutableArray *)[localFiles sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    /*[self setFiles:[NSMutableArray array]];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSLog(@"Searching for Files at Path: %@", documentsPath);
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    BOOL isDirectory;
    NSArray *localFiles = [NSArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsPath error:nil]];
    for (int i=0; i<[localFiles count]; i++) {
        NSString *itemPath = [NSString stringWithFormat:@"%@/%@", documentsPath, [localFiles objectAtIndex:i]];
        if ([fileManager fileExistsAtPath:itemPath isDirectory:&isDirectory] && !isDirectory) {
            [[self files] addObject:[localFiles objectAtIndex:i]];
            NSLog(@"Found File: %@", [localFiles objectAtIndex:i]);
        } else {
            NSLog(@"Found Directory: %@", [localFiles objectAtIndex:i]);
            NSArray *directoryFiles = [NSArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:itemPath error:nil]];
            for (int j=0; j<[directoryFiles count]; j++) {
                NSString *subItemPath = [NSString stringWithFormat:@"%@/%@", itemPath, [directoryFiles objectAtIndex:j]];
                if ([fileManager fileExistsAtPath:subItemPath isDirectory:&isDirectory] && !isDirectory) {
                    [fileManager moveItemAtPath:subItemPath toPath:[NSString stringWithFormat:@"%@/%@", documentsPath, [directoryFiles objectAtIndex:j]] error:nil];
                    [[self files] addObject:[directoryFiles objectAtIndex:j]];
                    NSLog(@"Moving File from Subdirectory: %@", subItemPath);
                }
            }
        }
    }
    [fileManager release];*/
    [self.fileTable reloadData];
    NSLog(@"Loaded Files");
}

- (void) showActionSheet {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Email", nil];
    [sheet showFromTabBar:((iTransferAppDelegate *)UIApplication.sharedApplication.delegate).tabBarController.tabBar];
    [sheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex==0) {
        //delete selected files
        for (int i=0; i<self.files.count; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            if ([self.fileTable cellForRowAtIndexPath:indexPath].isSelected) {
                [self.fileTable deselectRowAtIndexPath:indexPath animated:YES];
                [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", self.directory, [self.files objectAtIndex:indexPath.row]] error:nil];
            }
        }
        NSLog(@"Deleting (%d) files", self.fileTable.indexPathsForSelectedRows.count);
        if (self.fileTable.indexPathsForSelectedRows.count==0) {
            self.navigationItem.rightBarButtonItem = self.editButtonItem;
        }
    } else if (buttonIndex==1) {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
            mc.mailComposeDelegate = self;
            
            [mc setSubject:NSLocalizedString(@"MAIL_COMPOSER_DEFAULT_SUBJECT", nil)];
            for (NSIndexPath *indexPath in self.fileTable.indexPathsForSelectedRows) {
                NSString *filePath = [NSString stringWithFormat:@"%@/%@", self.directory, [self.files objectAtIndex:indexPath.row]];
                BOOL isDir = NO;
                [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
                if (!isDir) {
                    [mc addAttachmentData:[NSData dataWithContentsOfFile:filePath] mimeType:nil fileName:[self.files objectAtIndex:indexPath.row]];
                }
            }
            [mc setMessageBody:NSLocalizedString(@"MAIL_COMPOSER_DEFAULT_MESSAGE", nil) isHTML:NO];
            
            //[self presentModalViewController:mc animated:YES];
            [self presentViewController:mc animated:YES completion:nil];
            
            [mc release];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"MAIL_UNSUPPORTED_ALERT_TITLE", nil)
                                                            message:NSLocalizedString(@"MAIL_UNSUPPORTED_ALERT_MESSAGE", nil)
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	//[self dismissModalViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) directoryDidChange:(DirectoryWatcher *)folderWatcher {
    NSLog(@"DirectoryWatcher: directory updated");
    [self reloadFiles];
}

- (UIImage *) getIconForFileAtPath:(NSString *)path {
    NSString *extension = path.pathExtension;
    NSString *imageName = @"file";
    if ([extension isEqualToString:@""]) {
        imageName = @"folder";
    } else if ([extension isEqualToString:@"doc"] || [extension isEqualToString:@"pages"]) {
         extension = @"docx";
    } else if ([extension isEqualToString:@"ppt"] || [extension isEqualToString:@"keynote"]) {
        extension = @"pptx";
    } else if ([extension isEqualToString:@"xls"] || [extension isEqualToString:@"numbers"]) {
        extension = @"xlsx";
    } else if ([extension isEqualToString:@"htm"]) {
        extension = @"html";
    } else if ([extension isEqualToString:@"jpg"]) {
        extension = @"jpeg";
    } else if ([extension isEqualToString:@"aac"]) {
        extension = @"m4a";
    } else if ([extension isEqualToString:@"text"]) {
        extension = @"txt";
    } else if ([extension isEqualToString:@"tif"]) {
        extension = @"tiff";
    }
    if ([extension isEqualToString:@"ai"]    ||
        [extension isEqualToString:@"avi"]   ||
        [extension isEqualToString:@"bmp"]   ||
        [extension isEqualToString:@"css"]   ||
        [extension isEqualToString:@"docx"]  ||
        [extension isEqualToString:@"flv"]   ||
        [extension isEqualToString:@"gif"]   ||
        [extension isEqualToString:@"html"]  ||
        [extension isEqualToString:@"ini"]   ||
        [extension isEqualToString:@"ipb"]   ||
        [extension isEqualToString:@"jpeg"]  ||
        [extension isEqualToString:@"js"]    ||
        [extension isEqualToString:@"m4a"]   ||
        [extension isEqualToString:@"mov"]   ||
        [extension isEqualToString:@"mp3"]   ||
        [extension isEqualToString:@"mpeg"]  ||
        [extension isEqualToString:@"pdf"]   ||
        [extension isEqualToString:@"php"]   ||
        [extension isEqualToString:@"png"]   ||
        [extension isEqualToString:@"pptx"]  ||
        [extension isEqualToString:@"psd"]   ||
        [extension isEqualToString:@"rar"]   ||
        [extension isEqualToString:@"rtf"]   ||
        [extension isEqualToString:@"tiff"]  ||
        [extension isEqualToString:@"txt"]   ||
        [extension isEqualToString:@"wav"]   ||
        [extension isEqualToString:@"wma"]   ||
        [extension isEqualToString:@"wmv"]   ||
        [extension isEqualToString:@"xlsx"]  ||
        [extension isEqualToString:@"zip"]) {
        imageName = [NSString stringWithFormat:@"%@", extension];
    }
    return [UIImage imageNamed:imageName];
}

- (void) enableServer {
    if (self.webServer.running) {
        NSString *serverURL = [NSString stringWithFormat:@"%@:%@", [UDID getPrivateIP], @"8080"];
        NSString *alertMessage = [NSString stringWithFormat:@"The server is running and can by accessed from the following URL: \n \n %@" ,serverURL];
        UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Server Already Running" message:alertMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Restart", @"Stop", nil];
        [a setTag:1343];
        [a show];
        [a release];
    } else {
        [self.webServer start];
    }
}

- (void) webServerStarted:(WebServer *)server {
    NSString *serverURL = [NSString stringWithFormat:@"%@:%@", [UDID getPrivateIP], @"8080"];
    NSString *alertMessage = [NSString stringWithFormat:@"To connect, verity that your computer is on the same WiFi network. Then, type the following in the web browser's address bar: \n \n %@" ,serverURL];
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"File Server Started" message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [a show];
    [a release];
    [self.navigationController setToolbarHidden:NO animated:YES];
    UIBarButtonItem *label = [[UIBarButtonItem alloc] initWithTitle:@"File Server On" style:UIBarButtonItemStylePlain target:nil action:nil];
    UIBarButtonItem	*flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Turn Off" style:UIBarButtonItemStyleBordered target:self.webServer action:@selector(stop)];
    [self.navigationController.toolbar setItems:[NSArray arrayWithObjects:label, flex, button, nil] animated:YES];
    [label release];
    [flex release];
    [button release];
}

- (void) webServerStopped:(WebServer *)server {
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void) webServerFailed:(WebServer *)server {
    UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"Unable to Start Server" message:@"To access your files from your computer, please make sure this device and your computer is connected to the same WiFi network." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [a show];
    [a release];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag==1343) {
        if (buttonIndex==1) {
            [self.webServer stop];
            [self.webServer start];
        } else if (buttonIndex==2) {
            [self.webServer stop];
        }
    }
}

- (void) didMoveToParentViewController:(UIViewController *)parent
{
    //This is a hack that'll bring up the toolbar when going back if the server is running
    if ([self.navigationController.visibleViewController isMemberOfClass:[FileListController class]] && self.webServer.isRunning) {
        [self.navigationController setToolbarHidden:NO animated:NO];
        
        UIBarButtonItem *label = [[UIBarButtonItem alloc] initWithTitle:@"File Server On" style:UIBarButtonItemStylePlain target:nil action:nil];
        UIBarButtonItem	*flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Turn Off" style:UIBarButtonItemStyleBordered target:self.webServer action:@selector(stop)];
        [self.navigationController.toolbar setItems:[NSArray arrayWithObjects:label, flex, button, nil] animated:NO];
        [label release];
        [flex release];
        [button release];
    }
}

- (void)dealloc
{
    NSLog(@"FileListController dealloc Called");
    [delegate release];
    [files release];
    [fileTable release];
    [directoryWatcher invalidate];
	directoryWatcher.delegate = nil;
	[directoryWatcher release];
    [_directory release];
    [_webServer release];
    [super dealloc];
}

@end
