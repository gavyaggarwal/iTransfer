//
//  UpgradeView.h
//  iTransfer
//
//  Created by Gavy Aggarwal on 11/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#define PRODUCT_IDENTIFIER @"com.aggarwalcreations.itransfer.sendbigfiles";
#define TESTING_MODE 0;

@protocol UpgradeViewDelegate <NSObject>
@required
-(void)upgradeViewDismissed;
@end

@interface UpgradeView : UIViewController <SKProductsRequestDelegate, SKPaymentTransactionObserver, UIAlertViewDelegate> {
    id <UpgradeViewDelegate> delegate;
    SKProductsRequest *productsRequest;
}

@property (retain) id delegate;
@property (retain, nonatomic) IBOutlet UIButton *upgradeButton;
@property (retain, nonatomic) IBOutlet UIButton *cancelButton;
@property (retain) SKProductsRequest *productsRequest;
@property (retain, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (retain) SKProduct *product;

- (IBAction) cancel:(id)sender;
- (IBAction) upgrade:(id)sender;
- (void) prepareToUpgrade;
- (void) completeTransaction:(SKPaymentTransaction *)transaction;
- (void) failedTransaction:(SKPaymentTransaction *)transaction;
- (void) restoreTransaction:(SKPaymentTransaction *)transaction;
- (void) showIndicator;
- (void) hideIndicator;
- (BOOL) validatePurchase:(NSData *)receipt;
- (NSString *) encode:(const uint8_t *)input length:(NSInteger)length;
- (IBAction)activatePurchase;

@end