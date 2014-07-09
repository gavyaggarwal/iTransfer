#import "FileViewerController.h"

@implementation FileViewerController
@synthesize tbView;
@synthesize fileIconView, fileNameLabel, documentInteractionController, filePath, fileInfo;
@synthesize fileURL = _fileURL;
@synthesize fileIcon = _fileIcon;

- (id) initWithFilePath:(NSString *)path andIcon:(UIImage *)icon {
    self = [super init];
    if (self) {
        [self setFileURL:[NSURL fileURLWithPath:path]];
        [self setFileIcon:icon];
    }
    return self;
}

- (void)viewDidLoad
{
    self.hidesBottomBarWhenPushed = YES;
    
    [self.navigationController setToolbarHidden:YES animated:YES];
    [self setTitle:self.fileURL.path.lastPathComponent];
    [self.fileIconView setImage:self.fileIcon];
    [self.fileNameLabel setText:self.fileURL.path.lastPathComponent];
    
    [self setDocumentInteractionController:[UIDocumentInteractionController interactionControllerWithURL:self.fileURL]];
    [[self documentInteractionController] setDelegate:self];
    
    NSLog(@"Opening File At: %@ (Type: %@)", self.fileURL.path, self.documentInteractionController.UTI);
    
    [self setFileInfo:[NSMutableArray array]];
    [[self fileInfo] addObject:[self getFormattedFileSize]];   //add file size
    
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)self.fileURL.path.pathExtension, NULL);
    CFStringRef fileType = UTTypeCopyDescription(fileUTI);
    [[self fileInfo] addObject:[NSString stringWithFormat:@"%@", fileType]];  //add file type
    CFRelease(fileType);
    if (UTTypeConformsTo(fileUTI, kUTTypeAudio)) {
        AVPlayer *audioPlayer = [[AVPlayer alloc] initWithURL:[self filePath]];
        NSString *audioTitle = @"(Not Found)";
        NSString *audioArtist = @"(Not Found)";
        NSString *audioAlbum = @"(Not Found)";
        NSLog(@"Opening Song with Metadata: %@", audioPlayer.currentItem.asset.commonMetadata);
        for (AVMetadataItem *item in [[[audioPlayer currentItem] asset] commonMetadata]) {
            if ([[item commonKey] isEqualToString:AVMetadataCommonKeyTitle]) {
                audioTitle = [item stringValue];
            } else if ([[item commonKey] isEqualToString:AVMetadataCommonKeyArtist]) {
                audioArtist = [item stringValue];
            } else if ([[item commonKey] isEqualToString:AVMetadataCommonKeyAlbumName]) {
                audioAlbum = [item stringValue];
            }
        }
        NSLog(@"Audio Info: %@(Title), %@(Artist), %@(Album)", audioTitle, audioArtist, audioAlbum);
        [[self fileInfo] addObject:audioTitle];
        [[self fileInfo] addObject:audioArtist];
        [[self fileInfo] addObject:audioAlbum];
        [audioPlayer release];
    }
    CFRelease(fileUTI);
    
    [super viewDidLoad];
}

- (void)dealloc {
    [documentInteractionController release];
    [fileIconView release];
    [fileNameLabel release];
    [filePath release];
    [fileInfo release];
    [tbView release];
    [_fileURL release];
    [_fileIcon release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setDocumentInteractionController:nil];
    [self setFileIconView:nil];
    [self setFileNameLabel:nil];
    [self setFilePath:nil];
    [self setFileInfo:nil];
    [self setTbView:nil];
    [self setFileURL:nil];
    [self setFileIcon:nil];
    [super viewDidUnload];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
	//[self dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)interactionController
{
    //return self;
    return [self navigationController];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section==0) {
        return @"Actions";
    } else if (section==1) {
        return @"Details";
    }
    return @"";
}

- (NSInteger) tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    if (section==0) {
        CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)self.fileURL.path.pathExtension, NULL);
        int rows;
        if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
            rows = 4; //add option to save to library
        } else {
            rows = 3;
        }
        CFRelease(fileUTI);
        return rows;
    } else if (section==1) {
        return [[self fileInfo] count];
    };
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fileViewer"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"fileViewer"] autorelease];
        
        /*if ([UIImage instancesRespondToSelector:@selector(resizableImageWithCapInsets:)]) {
            UIImageView *selectionView = [[UIImageView alloc] initWithImage:nil];
            [cell setSelectedBackgroundView:selectionView];
            [selectionView release];
        } else {*/
            [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        //}
    }
    /*if ([UIImage instancesRespondToSelector:@selector(resizableImageWithCapInsets:)]) {
        UIImage *selectionBackground;
        NSInteger sectionRows = [self.tbView numberOfRowsInSection:[indexPath section]];
        NSInteger row = [indexPath row];
        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(22, 75, 21, 74);
        if (row == 0 && row == sectionRows - 1) {
            selectionBackground = [[UIImage imageNamed:@"cell-selection-only.png"] resizableImageWithCapInsets:edgeInsets];
        } else if (row == 0) {
            selectionBackground = [[UIImage imageNamed:@"cell-selection-top.png"] resizableImageWithCapInsets:edgeInsets];
        } else if (row == sectionRows - 1) {
            selectionBackground = [[UIImage imageNamed:@"cell-selection-bottom.png"] resizableImageWithCapInsets:edgeInsets];
        } else {
            selectionBackground = [[UIImage imageNamed:@"cell-selection-middle.png"] resizableImageWithCapInsets:edgeInsets];
        }
        ((UIImageView *)cell.selectedBackgroundView).image = selectionBackground;
    }*/
    if ([indexPath section]==0) {
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [[cell textLabel] setText:nil];
        switch ([indexPath row]) {
            case 0:
                [[cell detailTextLabel] setText:@"View"];
                break;
            case 1:
                [[cell detailTextLabel] setText:@"Email"];
                break;
            case 2:
                [[cell detailTextLabel] setText:@"Open In"];
                break;
            case 3:
                [[cell detailTextLabel] setText:@"Save to Gallery"];
                break;
            default:
                break;
        }
    } else if ([indexPath section]==1) {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        switch ([indexPath row]) {
            case 0:
                [[cell textLabel] setText:@"size"];
                break;
            case 1:
                [[cell textLabel] setText:@"type"];
                break;
            case 2:
                [[cell textLabel] setText:@"title"];
                break;
            case 3:
                [[cell textLabel] setText:@"artist"];
                break;
            case 4:
                [[cell textLabel] setText:@"album"];
                break;
            default:
                break;
        }
        [[cell detailTextLabel] setText:[[self fileInfo] objectAtIndex:[indexPath row]]];
    }
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([indexPath section]==0) {
        if ([indexPath row]==0) {
            [[self documentInteractionController] presentPreviewAnimated:TRUE];
        }
        if ([indexPath row]==1) {
            if ([MFMailComposeViewController canSendMail]) {
                
                MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
                mailComposer.mailComposeDelegate = self;
                
                [mailComposer setSubject:NSLocalizedString(@"MAIL_COMPOSER_DEFAULT_SUBJECT", nil)];
                [mailComposer addAttachmentData:[NSData dataWithContentsOfURL:self.fileURL] mimeType:self.documentInteractionController.UTI fileName:self.fileURL.path.lastPathComponent];
                [mailComposer setMessageBody:NSLocalizedString(@"MAIL_COMPOSER_DEFAULT_MESSAGE", nil) isHTML:NO];
                
                //[self presentModalViewController:mailComposer animated:YES];
                [self presentViewController:mailComposer animated:YES completion:nil];
                
                [mailComposer release];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"MAIL_UNSUPPORTED_ALERT_TITLE", nil)
                                                                message:NSLocalizedString(@"MAIL_UNSUPPORTED_ALERT_MESSAGE", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
                [alert release];
            }
        } else if ([indexPath row]==2) {
            //[[self documentInteractionController] presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
            CGRect f = [self.tbView cellForRowAtIndexPath:indexPath].frame;
            [[self documentInteractionController] presentOpenInMenuFromRect:CGRectMake(f.origin.x, f.origin.y+f.size.height, f.size.width, f.size.height) inView:[self view] animated:YES];
        } else if ([indexPath row]==3) {
            CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)self.fileURL.path.lastPathComponent, NULL);
            if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
                //save to gallery
                NSLog(@"Saving Image to Gallery");
                UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:[NSData dataWithContentsOfURL:self.fileURL]], nil, nil, nil);
            }
            CFRelease(fileUTI);
        }
    }
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *) getFormattedFileSize {
    NSDictionary *fileProperties = [[NSFileManager defaultManager] attributesOfItemAtPath:self.fileURL.path error:nil];
    unsigned long long size = [fileProperties fileSize];
    NSString *formattedString = nil;
    if (size == 0) 
		formattedString = @"Empty File (0 bytes)";
	else 
		if (size > 0 && size < 1024) 
			formattedString = [NSString stringWithFormat:@"%qu bytes", size];
        else 
            if (size >= 1024 && size < pow(1024, 2)) 
                formattedString = [NSString stringWithFormat:@"%.1f KB", (size / 1024.)];
            else 
                if (size >= pow(1024, 2) && size < pow(1024, 3))
                    formattedString = [NSString stringWithFormat:@"%.2f MB", (size / pow(1024, 2))];
                else 
                    if (size >= pow(1024, 3)) 
                        formattedString = [NSString stringWithFormat:@"%.3f GB", (size / pow(1024, 3))];
	
	return formattedString;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

@end
