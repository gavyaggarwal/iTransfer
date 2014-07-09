#import <Foundation/Foundation.h>

@class DirectoryWatcher;

@protocol DirectoryWatcherDelegate <NSObject>
@required
- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher;
@end

@interface DirectoryWatcher : NSObject 
{
	id <DirectoryWatcherDelegate> delegate;
    
	int dirFD;
    int kq;

	CFFileDescriptorRef dirKQRef;
}
@property (nonatomic, assign) id <DirectoryWatcherDelegate> delegate;

+ (DirectoryWatcher *)watchFolderWithPath:(NSString *)watchPath delegate:(id<DirectoryWatcherDelegate>)watchDelegate;
- (void)invalidate;
@end
