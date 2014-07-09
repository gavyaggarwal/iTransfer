//
//  TransferList.m
//  iTransfer
//
//  Created by Gavy Aggarwal on 5/22/13.
//
//

#import "TransferList.h"

@implementation TransferList

@synthesize delegate = _delegate;
@synthesize incomingFiles = _incomingFiles;
@synthesize outgoingFiles = _outgoingFiles;

- (id)init
{
    self = [super init];
    if (self) {
        NSLog(@"TransferList init Called");
        self.incomingFiles = [NSMutableArray array];
        self.outgoingFiles = [NSMutableArray array];
    }
    return self;
}

- (BOOL) validateFile:(TransferFile *)file {
    NSLog(@"TransferList validateFile Called");
    if([NSFileManager.defaultManager attributesOfItemAtPath:file.filePath error:nil].fileSize>(5*1024*1024) && ![[NSUserDefaults standardUserDefaults] boolForKey:@"isSendBigFilesPurchased"]) {
        //if the file size is over 5 MB and the iAP is not purchased
        file.isReady = NO;
        [self setLabelOfFile:file toLabel:NSLocalizedString(@"PURCHASE_PROMPT_LABEL", nil)];
        return false;
    } else {
        return true;
    }
}

- (BOOL) addFile:(TransferFile *)file toTransferList:(TransferListType)listType {
    NSLog(@"TransferList addFile Called %@", file);
    if (listType==TransferListTypeIncoming) {
        [self.incomingFiles addObject:file];
        [self.delegate fileListUpdated:TransferListTypeIncoming];
    } else if (listType==TransferListTypeOutgoing) {
        NSMutableArray *newOutgoingFiles = [self.outgoingFiles.mutableCopy autorelease];
        [newOutgoingFiles addObject:file];
        [self setOutgoingFiles:newOutgoingFiles];
        [self.delegate fileListUpdated:TransferListTypeOutgoing];
    } else {
        return NO;
    }
    return YES;
}

- (BOOL) removeFile:(TransferFile *)file fromTransferList:(TransferListType)listType {
    NSLog(@"TransferList removeFile Called %@", file);
    NSIndexPath *indexPath = [self getIndexPathOfFile:file];
    if (indexPath==nil) {
        return NO;
    }
    if (indexPath.section==0) {
        [self.incomingFiles removeObjectAtIndex:indexPath.row];
        [self.delegate fileListUpdated:TransferListTypeIncoming];
    } else if (indexPath.section==1) {
        [self.outgoingFiles removeObjectAtIndex:indexPath.row];
        [self.delegate fileListUpdated:TransferListTypeOutgoing];
    }
    return YES;
}

- (TransferFile *) getFileWithName:(NSString *)name fromTransferList:(TransferListType)listType {
    NSLog(@"TransferList getFileWithName Called: %@", name);
    for (TransferFile *f in self.outgoingFiles) {
        if (f.isReady==YES) {
            //For a file to have been sent, it must be in the outgoing list and ready
            if ([f.fileName isEqualToString:name]) {
                return f;
            }
        }
    }
    return nil;
}

- (void) setLabelOfFile:(TransferFile *)file toLabel:(NSString *)label {
    NSLog(@"TransferList setLabelOfFile Called: %@", label);
    [file setLabel:label];
    [self.delegate fileListUpdated:TransferListTypeOutgoing];
}

- (NSIndexPath *) getIndexPathOfFile:(TransferFile *)file {
    NSLog(@"TransferList getIndexPathOfFile Called: %@", file);
    //Search Incoming File List
    for (int i=0; i<self.incomingFiles.count; i++) {
        if ((TransferFile *)[self.incomingFiles objectAtIndex:i] == file) {
            return [NSIndexPath indexPathForRow:i inSection:0];
        }
    }
    //Search Outgoing File List
    for (int i=0; i<self.outgoingFiles.count; i++) {
        if ((TransferFile *)[self.outgoingFiles objectAtIndex:i] == file) {
            return [NSIndexPath indexPathForRow:i inSection:1];
        }
    }
    return nil;
}

- (TransferFile *) nextFileToSend {
    NSLog(@"TransferList nextFileToSend Called");
    for (TransferFile *f in self.outgoingFiles) {
        NSLog(@"Analyzing File (Ready: %d, Path: %@, Name: %@)", f.isReady, f.filePath, f.fileName);
        if (f.isReady==YES) {            
            //Format File Name
            NSString *fileNameUnformatted = [f fileName];
            NSMutableString *fileNameFormatted = [NSMutableString stringWithCapacity:fileNameUnformatted.length];
            
            NSScanner *scanner = [NSScanner scannerWithString:fileNameUnformatted];
            NSMutableCharacterSet *allowedCharacters = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
            [allowedCharacters addCharactersInString:@". "];
            
            while (scanner.isAtEnd==NO) {
                NSString *buffer;
                if ([scanner scanCharactersFromSet:allowedCharacters intoString:&buffer]) {
                    [fileNameFormatted appendString:buffer];
                } else {
                    [scanner setScanLocation:([scanner scanLocation] + 1)];
                }
            }
            [allowedCharacters release];
            [f setFileName:fileNameFormatted];
            NSLog(@"File Name Formatted (\"%@\" -> \"%@\")", fileNameUnformatted, fileNameFormatted);
            
            return f;
        }
    }
    return nil;
}

- (TransferFile *) incomingFile {
    NSLog(@"TransferList incomingFile Called");
    return [self.incomingFiles lastObject];
}

- (void) cleanList {
    NSLog(@"TransferList cleanList Called");
    NSMutableArray *newOutgoingFiles = self.outgoingFiles.mutableCopy;
    for (TransferFile *f in self.outgoingFiles) {
        if (f.isReady==NO && ![f.label isEqualToString:@"Processing"]) {
            [newOutgoingFiles removeObject:f];
        }
    }
    self.outgoingFiles = newOutgoingFiles;
    [self.delegate fileListUpdated:TransferListTypeOutgoing];
}

- (void) clear {
    NSLog(@"TransferList clear Called");
    [self.incomingFiles removeAllObjects];
    [self.outgoingFiles removeAllObjects];
}

#pragma mark -
#pragma mark UITableViewDataSource


- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TRANSFER_TABLE"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"TRANSFER_TABLE"] autorelease];
        
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
        NSInteger sectionRows = [tableView numberOfRowsInSection:[indexPath section]];
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
    if (indexPath.section==0) {
        if (self.incomingFiles.count==0) {
            cell.textLabel.text = @"No Incoming File";
            cell.detailTextLabel.text = @"";
        } else {
            cell.textLabel.text = [(TransferFile *)[self.incomingFiles objectAtIndex:indexPath.row] fileName];
            cell.detailTextLabel.text = [(TransferFile *)[self.incomingFiles objectAtIndex:indexPath.row] label];
        }
    } else if (indexPath.section==1) {
        if (self.outgoingFiles.count==0) {
            cell.textLabel.text = @"No Outgoing Files";
            cell.detailTextLabel.text = @"";
        } else {
            cell.textLabel.text = [(TransferFile *)[self.outgoingFiles objectAtIndex:indexPath.row] fileName];
            cell.detailTextLabel.text = [(TransferFile *)[self.outgoingFiles objectAtIndex:indexPath.row] label];
        }
    }
    return cell;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section==0) {
        return (self.incomingFiles.count==0) ? 1 : self.incomingFiles.count;
    } else if (section==1) {
        return (self.outgoingFiles.count==0) ? 1 : self.outgoingFiles.count;
    } else {
        return 0;
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section==0) {
        return @"Incoming Files";
    } else {
        return @"Outgoing Files";
    }
}

/*
– sectionIndexTitlesForTableView:
– tableView:sectionForSectionIndexTitle:atIndex:
– tableView:titleForHeaderInSection:
– tableView:titleForFooterInSection:
*/
@end
