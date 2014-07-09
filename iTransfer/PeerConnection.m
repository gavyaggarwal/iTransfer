//
//  PeerConnection.m
//  iTransfer
//
//  Created by Gavy Aggarwal on 1/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PeerConnection.h"
#import "UDID.h"

@implementation PeerConnection
@synthesize delegate = _delegate;
@synthesize isConnected = _isConnected;
@synthesize isSending = _isSending;
@synthesize session = _session;
@synthesize peerName = _peerName;
@synthesize peers = _peers;
@synthesize packetsTotal = _packetsTotal;
@synthesize packetsReceived = _packetsReceived;
@synthesize fileHandle = _fileHandle;
@synthesize timer = _timer;
@synthesize transferList = _transferList;

- (id) init {
    self = [super init];
    if (self) {
        NSLog(@"PeerConnection init Called");
        transferQueue = dispatch_queue_create("com.aggarwalcreations.itransfer.transfer_queue", NULL);
        [self setIsConnected:NO];
        [self setIsSending:NO];
        NSMutableArray *p = [[NSMutableArray alloc] init];
        [self setPeers:p];
        [p release];
        TransferList *tl = [[TransferList alloc] init];
        [self setTransferList:tl];
        [self.transferList setDelegate:self];
        [tl release];
    }
    return self;
}

#pragma mark -

- (void) reset {
    NSLog(@"PeerConnection reset Called");
    [self setIsConnected:NO];
    [self setIsSending:NO];
    [self.session setAvailable:NO];
    [self.session setDataReceiveHandler:nil withContext:nil];
    [self.session setDelegate:nil];
    //[self.session release];
    [self setPeerName:nil];
    [self setPacketsTotal:0];
    [self setPacketsReceived:0];
    [self setFileHandle:nil];
    [self setTimer:nil];
    [self.transferList clear];
    //Reset Connection Here
}

- (void) processMessage:(NSData *)data {
    NSLog(@"PeerConnection processMessage Called");
    
    NSString *contents = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    PeerConnectionMessageType messageType = [[contents substringToIndex:1] intValue];
    NSString *message = [contents substringFromIndex:2];
    
    //NSLog(@"Received Message: %@", message);
    
    //Send to appropriate handler for message
    if(messageType==PeerConnectionMessageTypeFileComing) {
        NSLog(@"PeerConnection processMessage PeerConnectionMessageTypeFileComing (%@)", message);
        
        //prepare file for writing
        NSRange spacer = [message rangeOfString:@":"];
        NSString *encodedFileName = [message substringWithRange:NSMakeRange(0, spacer.location)];
        NSString *fileName = [NSString stringWithUTF8String:[[UDID decodeBase64WithString:encodedFileName] bytes]];
        NSLog(@"File Name (encoded: %@, decoded: %@)", encodedFileName, fileName);
        [self setPacketsTotal:[[message substringWithRange:NSMakeRange(spacer.location + 1, message.length - spacer.location - 1)] intValue]];
        NSString *path = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), fileName];   //file already needs to be existing for this to work
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:path]) {
            [fileManager removeItemAtPath:path error:nil];
        }
        [fileManager createFileAtPath:path contents:nil attributes:nil];
        [self setFileHandle:[NSFileHandle fileHandleForWritingAtPath:path]];
        if(self.fileHandle==nil) {
            NSLog(@"PeerConnection processMessage PeerConnectionMessageTypeFileComing Can't Get File Handle");
        }
        //keep the handle open because we'll need it to write to the file (it closes after)
        NSLog(@"PeerConnection processMessage PeerConnectionMessageTypeFileComing Preparing File for Writing (%@)", path);
        
        TransferFile *tf = [[TransferFile alloc] initWithFilePath:path fileName:path.lastPathComponent label:@"Starting" isReady:NO];
        [self.transferList addFile:tf toTransferList:TransferListTypeIncoming];
        [tf release];
        
    } else if(messageType==PeerConnectionMessageTypeFileReceived) {
        NSLog(@"PeerConnection processMessage PeerConnectionMessageTypeFileReceived (%@)", message);
        
        NSString *fileName = [NSString stringWithUTF8String:[[UDID decodeBase64WithString:message] bytes]];
        NSLog(@"File Name: %@", fileName);
        //TransferFile *file = [self.transferList getFileWithName:fileName fromTransferList:TransferListTypeOutgoing];
        
        [self setIsSending:NO];
        
        TransferFile *file = self.transferList.nextFileToSend;  //This is a hack that'll give us the last sent file
        [self.transferList removeFile:file fromTransferList:TransferListTypeOutgoing];
        //[self processQueue];
    } else if(messageType==PeerConnectionMessageTypeAppVersion) {
        NSLog(@"PeerConnection processMessage PeerConnectionMessageTypeAppVersion (%@)", message);
        
        NSRange spacer = [message rangeOfString:@":"];
        NSString *version = message;
        NSString *hostModel = @"Unknown";
        if(spacer.location!=NSNotFound) {
            version = [message substringWithRange:NSMakeRange(0, spacer.location)];
            hostModel = [message substringWithRange:NSMakeRange(spacer.location + 1, message.length - spacer.location - 1)];
        }
        NSLog(@"Version %@ %@", version, hostModel);
        
        //Compare Versions
        if (![version isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]) {
            NSLog(@"PeerConnection processMessage PeerConnectionMessageTypeAppVersion Users are Running Different Versions");
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Version Warning" message:@"This device is running a different version of iTransfer than the device it is connected to. For everything to work properly, download the latest version of the app on both devices. Tap OK to continue with the current setup." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
                [alert release];
            });
        }
        
        //Determine Device Family
        NSString *deviceFamily = @"Unknown";
        if ([hostModel hasPrefix:@"iPhone"]) {
            deviceFamily = @"iPhone";
        } else if ([hostModel hasPrefix:@"iPad"]) {
            deviceFamily = @"iPad";
        } else if ([hostModel hasPrefix:@"iPod"]) {
            deviceFamily = @"iPod";
        }
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if ([[self delegate] respondsToSelector:@selector(peerDeviceFamilyDetermined:)]) {
                [[self delegate] peerDeviceFamilyDetermined:deviceFamily];
            }
        });
    } else {
        NSLog(@"PeerConnection processMessage Unknown Message Received (%@)", contents);
        //Alert User
    }
    [contents release];
}

- (void) appendData:(NSData *)data {
    NSLog(@"PeerConnection appendData Called (Packet %d)", self.packetsReceived);
    
    [self.fileHandle writeData:data];
    [self setPacketsReceived:(self.packetsReceived+1)];
    
    if(self.packetsReceived%20==1) {
        //increase efficiency by only updating progress and measuring speed after every 20/200 packets instead of every packet
        //self.incomingFile.label = [NSString stringWithFormat:@"%d Completed", packetsReceived/packetsTotal * 100];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.transferList setLabelOfFile:self.transferList.incomingFile toLabel:[NSString stringWithFormat:@"%d%% Completed (%d kb/s)", (int)((double)self.packetsReceived / (double)self.packetsTotal * 100.0), self.timer.speed]];
            
        });
        if (self.packetsReceived%200==1) {
            if (self.timer!=nil) {   //timer is running
                [[self timer] stopTimer];
                int speed = (int) (200.0/[[self timer] timeElapsedInSeconds]);
                [[self timer] setSpeed:speed];
            } else {
                Timer *t = [[Timer alloc] init];
                [self setTimer:t];
                [t release];
            }
            [[self timer] startTimer];
        }
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if ([[self delegate] respondsToSelector:@selector(fileProgressUpdated)]) {
                [[self delegate] fileProgressUpdated];
            }
        });
    }
    if(self.packetsReceived==self.packetsTotal) {
        
        [self.fileHandle closeFile];   //don't need to write to the file anymore
        
        NSString *path = self.transferList.incomingFile.filePath;
        if ([self.transferList validateFile:self.transferList.incomingFile]) {
            
            NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            
            NSString *fileExtension = path.pathExtension;
            NSString *filePrefix = @"file";
            if([fileExtension isEqualToString:@"jpg"]) {
                filePrefix = @"image";   //name file as image
                //} else if([fileExtension isEqualToString:@"m4a"]) {        This allows the file to keep it's original name
                //    filePrefix = @"audio";   //name file as audio
            } else if([fileExtension isEqualToString:@"mov"]) {
                filePrefix = @"video";   //name file as video
            } else {
                filePrefix = [path.lastPathComponent substringToIndex:((path.lastPathComponent.length-fileExtension.length)-1)];   //assume random file: removes "." and the extension of the file
            }
            NSLog(@"Received File (Prefix: %@ & Extension: %@)", filePrefix, fileExtension);
            
            int i = 2;
            NSString *finalDestination = [NSString stringWithFormat:@"%@/%@.%@", documentsPath, filePrefix, fileExtension];
            while ([NSFileManager.defaultManager fileExistsAtPath:finalDestination]) {
                finalDestination = [NSString stringWithFormat:@"%@/%@ (%d).%@", documentsPath, filePrefix, i, fileExtension];
                i++;
            }
            
            NSLog(@"PeerConnection appendData Final Save Location (%@)", finalDestination);
            
            [[NSFileManager defaultManager] moveItemAtPath:path toPath:finalDestination error:nil];
        } else {
            //prompt user to buy upgrade
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                if ([[self delegate] respondsToSelector:@selector(transferErrorOccured:)]) {
                    [[self delegate] transferErrorOccured:self.transferList.outgoingFiles];
                }
            });
        }
        
        [self setPacketsReceived:0];
        [self setPacketsTotal:0];
        
        NSString *encodedFileName = [UDID encodeBase64WithString:self.transferList.incomingFile.filePath.lastPathComponent];
        NSString *fileConfirmation = [NSString stringWithFormat:@"%d:%@", PeerConnectionMessageTypeFileReceived, encodedFileName];
        [self sendMessage:fileConfirmation];
        
        [self.transferList removeFile:self.transferList.incomingFile fromTransferList:TransferListTypeIncoming];
        [self setTimer:nil];
        
        NSInteger filesTransferred = [[[NSUserDefaults standardUserDefaults] objectForKey:@"files_transferred"] intValue];
        filesTransferred++;
        [[NSUserDefaults standardUserDefaults] setInteger:filesTransferred forKey:@"files_transferred"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.delegate fileReceived];
        });
    }
}

- (void) processQueue {
    NSLog(@"PeerConnection processQueue Called");
    dispatch_async(transferQueue, ^(void) {
        if (self.isSending==NO) {
            //Send next file
            TransferFile *file = self.transferList.nextFileToSend;
            if (file==nil) {
                //No more stuff to send
                return;
            }
            [self.transferList setLabelOfFile:file toLabel:@"Sending"];
            
            
            long long int size = ([[[NSFileManager defaultManager] attributesOfItemAtPath:file.filePath error:nil] fileSize]);
            long long int packets = size/1024;
            if (size%1024!=0) {
                packets++;
            }
            NSString *encodedFileName = [UDID encodeBase64WithString:file.fileName];
            NSString *message = [NSString stringWithFormat:@"%d:%@:%lld", PeerConnectionMessageTypeFileComing, encodedFileName, packets];
            NSLog(@"Sending Message: %@", message);
            
            [self setIsSending:YES];
            [self sendMessage:message];
            [self sendFile:file.filePath];
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                if ([[self delegate] respondsToSelector:@selector(fileSending)]) {
                    [[self delegate] fileSending];
                }
            });
        }
    });
}

- (void) sendFile:(NSString *)filePath {
    long long int size = ([[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize]);
    NSUInteger chunkSize = 1024;
    NSData *data;
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:filePath];
    do {
        data = [fh readDataOfLength:chunkSize];
        [self.session sendData:data toPeers:self.peers withDataMode:GKSendDataReliable error:nil];
    } while (fh.offsetInFile < size);
    [fh closeFile];
    NSLog(@"Sent File At Path: %@", filePath);
}

- (void) sendMessage:(NSString *)message {
    NSData *data = [message dataUsingEncoding:NSASCIIStringEncoding];
    [self.session sendData:data toPeers:self.peers withDataMode:GKSendDataReliable error:nil];
    NSLog(@"Sent Message (%@)", message);
}

- (void) dealloc {
    NSLog(@"PeerConnection dealloc Called");
    dispatch_release(transferQueue);
    [_delegate release];
    [_session release];
    [_peerName release];
    [_peers release];
    [_fileHandle release];
    [_timer release];
    [_transferList release];
    [super dealloc];
}

#pragma mark -
#pragma mark GKSessionDelegate

- (void)session:(GKSession *)transferSession peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
    if(state == GKPeerStateConnected){
        NSLog(@"Peer Connected: %@", peerID);
		[self.peers addObject:peerID]; //Add the peer to the Array
        [self setPeerName:[transferSession displayNameForPeer:peerID]];
        [self setIsConnected:YES];
		[transferSession setDataReceiveHandler:self withContext:nil]; //Used to acknowledge that we will be sending data
        NSString *versionCheck = [NSString stringWithFormat:@"%d:%@:%@", PeerConnectionMessageTypeAppVersion, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[UIDevice currentDevice] model]];
        [self sendMessage:versionCheck];
	} else if(state == GKPeerStateDisconnected) {
        NSLog(@"Peer Disconnected: %@", peerID);
        [self setIsConnected:NO];
    } else {
        NSLog(@"Unknown Peer State");
    }
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.delegate peerStateChanged:state];
    });
}

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context {
    dispatch_async(transferQueue, ^(void) {
        if(self.packetsTotal==0) {
            [self processMessage:data];
        } else {
            [self appendData:data];
        }
    });
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
    NSLog(@"Connection Request: %@",peerID);
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error {
    NSLog(@"Session Failed: %@",error.debugDescription);
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error {
    NSLog(@"Connection With Peer Failed: %@",error.debugDescription);
}

#pragma mark -
#pragma mark TransferListDelegate

- (void) fileListUpdated:(TransferListType)listType {
    if (listType==TransferListTypeIncoming) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if ([[self delegate] respondsToSelector:@selector(fileProgressUpdated)]) {
                //[[self delegate] fileProgressUpdated];
            }
        });
    } else if (listType==TransferListTypeOutgoing) {
        [self processQueue];
    }
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if ([[self delegate] respondsToSelector:@selector(queueUpdated:)]) {
            [[self delegate] queueUpdated:self.transferList.outgoingFiles.count];
        }
    });
}

@end
