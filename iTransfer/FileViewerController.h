#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/UTType.h>
#import <MobileCoreServices/UTCoreTypes.h>

@interface FileViewerController : UIViewController <MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate, UITableViewDelegate, UITableViewDataSource> {
    UIDocumentInteractionController *documentInteractionController;
    NSURL *filePath;
    NSMutableArray *fileInfo;
}

@property (retain) UIDocumentInteractionController *documentInteractionController;
@property (retain, nonatomic) IBOutlet UIImageView *fileIconView;
@property (retain, nonatomic) IBOutlet UILabel *fileNameLabel;
@property (retain) NSURL *filePath;
@property (retain) NSMutableArray *fileInfo;
@property (retain, nonatomic) IBOutlet UITableView *tbView;
@property (retain) NSURL *fileURL;
@property (retain) UIImage *fileIcon;

- (id) initWithFilePath:(NSString *)path andIcon:(UIImage *)icon;
- (NSString *) getFormattedFileSize;

@end
