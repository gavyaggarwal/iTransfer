//
//  Exporter.h
//  iTransfer
//
//  Created by Gavy Aggarwal on 6/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "FileListController.h"
#import "TransferFile.h"
#import <MobileCoreServices/UTType.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <dispatch/dispatch.h>
#import "TransferList.h"

@protocol ExporterDelegate <NSObject>
@required
- (void) exporterStateChangedDidCancel:(BOOL)canceled;
@end

@interface Exporter : NSObject <UIImagePickerControllerDelegate, MPMediaPickerControllerDelegate, FileListControllerDelegate, UINavigationControllerDelegate> {
    id <ExporterDelegate> delegate;
    dispatch_queue_t exportQueue;
}

@property (retain) id delegate;
@property (retain) TransferList *transferList;
@property (assign) dispatch_queue_t transferQueue;

- (NSString *) getExportFilePathWithExtension:(NSString *)extension;

typedef enum {
    ExporterMediaTypePhotoGallery= 1,
    ExporterMediaTypeMusicLibrary = 2,
    ExporterMediaTypeReceivedFile = 3
} ExporterMediaType;

@end
