//
//  TransferList.h
//  iTransfer
//
//  Created by Gavy Aggarwal on 5/22/13.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TransferFile.h"

typedef enum {
    TransferListTypeIncoming = 1,
    TransferListTypeOutgoing = 2
} TransferListType;

@protocol TransferListDelegate <NSObject>
@required
- (void) fileListUpdated:(TransferListType)listType;
@end

@interface TransferList : NSObject <UITableViewDataSource>

@property (retain) id <TransferListDelegate> delegate;
@property (retain) NSMutableArray *incomingFiles;
@property (retain) NSMutableArray *outgoingFiles;

- (BOOL) validateFile:(TransferFile *)file;
- (BOOL) addFile:(TransferFile *)file toTransferList:(TransferListType)listType;
- (BOOL) removeFile:(TransferFile *)file fromTransferList:(TransferListType)listType;
- (TransferFile *) getFileWithName:(NSString *)name fromTransferList:(TransferListType)listType;
- (void) setLabelOfFile:(TransferFile *)file toLabel:(NSString *)label;
- (NSIndexPath *) getIndexPathOfFile:(TransferFile *)file;
- (TransferFile *) nextFileToSend;
- (TransferFile *) incomingFile;
- (void) cleanList;
- (void) clear;

@end
