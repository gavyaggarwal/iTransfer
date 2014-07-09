//
//  Exporter.m
//  iTransfer
//
//  Created by Gavy Aggarwal on 6/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Exporter.h"

@implementation Exporter
@synthesize delegate = _delegate;
@synthesize transferList = _transferList;
@synthesize transferQueue = _transferQueue;

- (id) init {
    self = [super init];
    if (self) {
        NSLog(@"Exporter init Called");
        exportQueue = dispatch_queue_create("com.aggarwalcreations.itransfer.export_queue", NULL);
    }
    return self;
}

- (void) dealloc {
    NSLog(@"Exporter dealloc Called");
    dispatch_release(exportQueue);
    [_delegate release];
    [_transferList release];
    [super dealloc];
}

#pragma mark -

- (NSString *) getExportFilePathWithExtension:(NSString *)extension {
    NSString *exportFile = [NSString stringWithFormat:@"%@/temp%d.%@", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0], arc4random()%(100000000), extension];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:exportFile]) {
        //Delete File if it already exists
        [fileManager removeItemAtPath:exportFile error:nil];
    }
    return exportFile;
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [[self delegate] exporterStateChangedDidCancel:NO];
    picker = nil;
    
    dispatch_async(exportQueue, ^(void) {
        TransferFile *f = [[TransferFile alloc] initWithFilePath:nil fileName:nil label:nil isReady:YES];
        if (CFStringCompare((CFStringRef) [info objectForKey:UIImagePickerControllerMediaType], kUTTypeImage, 0) == kCFCompareEqualTo) {
            NSString *exportPath = [self getExportFilePathWithExtension:@"jpg"];
            [[NSFileManager defaultManager] createFileAtPath:exportPath contents:UIImageJPEGRepresentation([info valueForKey:UIImagePickerControllerOriginalImage], 1.0) attributes:nil];
            [f setFilePath:exportPath];
            [f setFileName:@"image.jpg"];
            [f setLabel:@"Waiting"];
        } else if (CFStringCompare((CFStringRef) [info objectForKey:UIImagePickerControllerMediaType], kUTTypeMovie, 0) == kCFCompareEqualTo) {
            NSURL *movieURL = [info valueForKey:UIImagePickerControllerMediaURL];
            [f setFilePath:[movieURL path]];
            [f setFileName:@"video.mov"];
            [f setLabel:@"Waiting"];
            NSLog(@"Movie Path: %@", [info valueForKey:UIImagePickerControllerMediaURL]);
        }
        dispatch_async(self.transferQueue, ^(void) {
            [self.transferList validateFile:f];
            [self.transferList addFile:f toTransferList:TransferListTypeOutgoing];
        });
        
        [f release];
    });
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [[self delegate] exporterStateChangedDidCancel:YES];
    picker = nil;
}

#pragma mark -
#pragma mark MPMediaPickerControllerDelegate

- (void) mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    [[self delegate] exporterStateChangedDidCancel:NO];
    
    dispatch_queue_t exportQueue2 = dispatch_queue_create("com.aggarwalcreations.itransfer.export_queue_2", NULL);   //We create another queue for increased exporting power (it can handle the whole music library!)
    dispatch_async(exportQueue, ^(void) {
        NSLog(@"Processing Song(s)");
        for (int i=0; i<mediaItemCollection.items.count; i++) {
            MPMediaItem *song = [[[mediaItemCollection items] objectAtIndex:i] retain];
            
            TransferFile *f = [[TransferFile alloc] initWithFilePath:nil fileName:[NSString stringWithFormat:@"%@.m4a", [song valueForProperty:MPMediaItemPropertyTitle]] label:@"Processing" isReady:NO];
            dispatch_async(self.transferQueue, ^(void) {
                [self.transferList addFile:f toTransferList:TransferListTypeOutgoing];
            });
            
            NSURL *assetURL = [song valueForProperty:MPMediaItemPropertyAssetURL];
            NSLog(@"Asset URL: %@", assetURL);
            if (assetURL!=nil) {
                dispatch_async(exportQueue2, ^(void) {
                    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
                    
                    NSString *exportPath = [self getExportFilePathWithExtension:@"m4a"];
                    
                    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:songAsset presetName:AVAssetExportPresetAppleM4A];
                    exporter.outputFileType = @"com.apple.m4a-audio";
                    exporter.outputURL = [NSURL fileURLWithPath:exportPath];
                    
                    //Set metadata
                    NSMutableArray *metadata = [NSMutableArray array];
                    NSArray *metadataKeyPairs = [NSArray arrayWithObjects:
                                                 [NSArray arrayWithObjects:AVMetadataCommonKeyTitle, MPMediaItemPropertyTitle, nil],
                                                 [NSArray arrayWithObjects:AVMetadataCommonKeyArtist, MPMediaItemPropertyArtist, nil],
                                                 [NSArray arrayWithObjects:AVMetadataCommonKeyAlbumName, MPMediaItemPropertyAlbumTitle, nil],
                                                 //[NSArray arrayWithObjects:AVMetadataCommonKeyArtwork, MPMediaItemPropertyArtwork, nil],
                                                 [NSArray arrayWithObjects:AVMetadataCommonKeyDescription, MPMediaItemPropertyComments, nil],
                                                 [NSArray arrayWithObjects:AVMetadataCommonKeyType, MPMediaItemPropertyMediaType, nil],
                                                 nil];
                    for (int i=0; i<metadataKeyPairs.count; i++) {
                        AVMutableMetadataItem *item = [[AVMutableMetadataItem alloc] init];
                        item.keySpace = AVMetadataKeySpaceCommon;
                        item.key = [[metadataKeyPairs objectAtIndex:i] objectAtIndex:0];
                        item.value = [song valueForProperty:[[metadataKeyPairs objectAtIndex:i] objectAtIndex:1]];
                        [metadata addObject:item];
                        [item release];
                    }
                    
                    exporter.metadata = metadata;
                    
                    NSLog(@"Exporting Music With Metadata: %@", exporter.metadata);
                    NSLog(@"Created Exporter (supportedFileTypes: %@)", exporter.supportedFileTypes);
                    NSLog(@"Exporting Audio to %@", exportPath);
                    
                    [exporter exportAsynchronouslyWithCompletionHandler:^{
                        if (exporter.status==AVAssetExportSessionStatusCompleted) {
                            [f setFilePath:exportPath];
                            [f setIsReady:YES];
                            dispatch_async(self.transferQueue, ^(void) {
                                if ([self.transferList validateFile:f]) {
                                    [self.transferList setLabelOfFile:f toLabel:@"Waiting"];
                                }
                            });
                        } else if (exporter.status==AVAssetExportSessionStatusFailed) {
                            NSError *exportError = exporter.error;
                            NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);
                            dispatch_async(self.transferQueue, ^(void) {
                                [self.transferList setLabelOfFile:f toLabel:NSLocalizedString(@"EXPORT_FAILURE_LABEL", nil)];
                            });
                        }
                    }];
                    [exporter release];
                });
            } else {
                dispatch_async(self.transferQueue, ^(void) {
                    [self.transferList setLabelOfFile:f toLabel:NSLocalizedString(@"MUSIC_NOT_FOUND_LABEL", nil)];
                });
            }
            [f release];
            [song release];
        }
    });
    //dispatch_release(exportQueue2);
}

- (void) mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    [[self delegate] exporterStateChangedDidCancel:YES];
}

#pragma mark -
#pragma mark FileListControllerDelegate

- (void) fileSelectedWithPath:(NSString *)path {
    [[self delegate] exporterStateChangedDidCancel:NO];
    
    dispatch_async(exportQueue, ^(void) {
        TransferFile *f = [[TransferFile alloc] initWithFilePath:path fileName:path.lastPathComponent label:@"Waiting" isReady:YES];
        dispatch_async(self.transferQueue, ^(void) {
            [self.transferList validateFile:f];
            [self.transferList addFile:f toTransferList:TransferListTypeOutgoing];
        });
        [f release];
    });
}

- (void) fileListCancelled {
    [[self delegate] exporterStateChangedDidCancel:YES];
}

@end
