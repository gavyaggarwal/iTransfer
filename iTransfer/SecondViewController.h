#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "FileListController.h"
#import "UpgradeView.h"
#import "PeerConnection.h"
#import "iTransferAppDelegate.h"
#import "UDID.h"
#import "TransferFile.h"
#import "Exporter.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <dispatch/dispatch.h>
#import "TransferList.h"

@interface SecondViewController : UIViewController <PeerConnectionDelegate, GKPeerPickerControllerDelegate, UITableViewDelegate, UIAlertViewDelegate, UpgradeViewDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, ExporterDelegate> {
    PeerConnection *connection;
    UIPopoverController *popover;
    Exporter *exporter;
    dispatch_queue_t transferQueue;
}

@property (retain) PeerConnection *connection;
@property (retain, nonatomic) IBOutlet UIView *disconnectedView;
@property (nonatomic, retain) IBOutlet UITableView *tbView;
@property (retain) UIPopoverController *popover;
@property (retain) Exporter *exporter;
@property (retain) UIAlertView *purchasePrompt;
@property (retain, nonatomic) IBOutlet UIScrollView *hud;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *spacerTop;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *spacerBottom;
@property (retain, nonatomic) IBOutlet UIView *spacer;

- (void) showPicker;
- (void) createDashboardWithPeerFamily:(NSString *)family;
- (void) scrollDashboard;
- (void) removeFileLimit;
- (void) reload;
- (void) openViewWithViewController:(UIViewController *)vc andFrame:(CGRect)f;
- (void) closeView;
- (void) confirmDisconnect;
- (void) sendFile:(UITapGestureRecognizer *)sender;

@end

