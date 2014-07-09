//
//  UpgradeView.m
//  iTransfer
//
//  Created by Gavy Aggarwal on 11/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UpgradeView.h"

@implementation UpgradeView
@synthesize delegate;
@synthesize upgradeButton;
@synthesize cancelButton;
@synthesize productsRequest;
@synthesize navigationBar;
@synthesize product = _product;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self prepareToUpgrade];
    [self setTitle:@"Upgrade"];
    
    /*if ([UIImage instancesRespondToSelector:@selector(resizableImageWithCapInsets:)]) {
        UIImage *bgImage = [[UIImage imageNamed:@"cell-selection-only.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(22, 75, 21, 74)];
        [self.upgradeButton setBackgroundImage:bgImage forState:UIControlStateHighlighted];
        [self.cancelButton setBackgroundImage:bgImage forState:UIControlStateHighlighted];
    }*/
}

- (void)viewDidUnload {
    [self setUpgradeButton:nil];
    [self setCancelButton:nil];
    [[self productsRequest] setDelegate:nil];
    [self setProductsRequest:nil];
    [self setNavigationBar:nil];
    [self setProduct:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}

- (IBAction)cancel:(id)sender {
    NSLog(@"Closing Upgrade View");
    //Close everything and return to home
    [[self productsRequest] setDelegate:nil];
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    [[self delegate] upgradeViewDismissed];
}

- (IBAction)upgrade:(id)sender {
    if (self.product==nil) {
        return;
    }
    NSLog(@"Upgrading App");
    SKPayment *payment = [SKPayment paymentWithProduct:self.product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    [self showIndicator];
    [self.upgradeButton setEnabled:NO];
    [self.cancelButton setEnabled:NO];
}

- (void) prepareToUpgrade {
    NSLog(@"UpgradeView prepareToUpgrade Called");
    if (![SKPaymentQueue canMakePayments]) {
        NSLog(@"Unable to Make Purchases on this Device");
        [[self upgradeButton] setTitle:@"Unable to Make Purchases" forState:UIControlStateNormal];
        return;
    }
    [self showIndicator];
    [[self upgradeButton] setTitle:@"Checking Availability" forState:UIControlStateNormal];
    NSString *prodID = PRODUCT_IDENTIFIER;
    SKProductsRequest *pr = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:prodID]];
    [self setProductsRequest:pr];
    [pr release];
    [[self productsRequest] setDelegate:self];
    [[self productsRequest] start];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSLog(@"Received Response: %@", response.products);
    SKProduct *product = [response.products objectAtIndex:0];
    NSLog(@"Product ID: %@", product.productIdentifier);
    NSString *prodID = PRODUCT_IDENTIFIER;
    if ([product.productIdentifier isEqualToString:prodID]) {
        //Ready to make purchase
        [self setProduct:product];
        NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [formatter setLocale:product.priceLocale];
        NSString *currency = [formatter stringFromNumber:product.price];
        [[self upgradeButton] setEnabled:YES];
        [[self upgradeButton] setTitle:[NSString stringWithFormat:@"Unlock (%@)", currency] forState:UIControlStateNormal];
    } else {
        [[self upgradeButton] setTitle:[NSString stringWithFormat:@"Product Not Available"] forState:UIControlStateNormal];
    }
    UIActivityIndicatorView *ai = (UIActivityIndicatorView *)[[self upgradeButton] viewWithTag:348];
    [ai stopAnimating];
    [ai removeFromSuperview];
}

- (void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    NSLog(@"Updated Transaction Queue");
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    }
}

- (void) completeTransaction: (SKPaymentTransaction *)transaction {
    [self validatePurchase:transaction.transactionReceipt];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
    [self cancel:nil];
}

- (void) restoreTransaction: (SKPaymentTransaction *)transaction {
    [self validatePurchase:transaction.originalTransaction.transactionReceipt];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
    [self cancel:nil];
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction {
    NSLog(@"Purchase Failed: %@", transaction.error.debugDescription);
    if (transaction.error.code != SKErrorPaymentCancelled) {
        [[self upgradeButton] setTitle:@"Error Purchasing Item" forState:UIControlStateNormal];
    }
    [self hideIndicator];
    [[self cancelButton] setEnabled:YES];
    [[self upgradeButton] setEnabled:YES];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) showIndicator {
    UIActivityIndicatorView *ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [ai setFrame:CGRectMake(self.upgradeButton.frame.size.width-self.upgradeButton.frame.size.height, 0, self.upgradeButton.frame.size.height, self.upgradeButton.frame.size.height)];
    [ai startAnimating];
    [ai setTag:348];
    [[self upgradeButton] addSubview:ai];
    [ai release];
}

- (void) hideIndicator {
    UIActivityIndicatorView *ai = (UIActivityIndicatorView *)[[self upgradeButton] viewWithTag:348];
    [ai stopAnimating];
    [ai removeFromSuperview];
}

- (BOOL) validatePurchase:(NSData *)receipt {
    [[self upgradeButton] setTitle:@"Validating Purchase" forState:UIControlStateNormal];
    NSString *url = NSLocalizedString(@"BASE_URL", nil);
    int isSandbox = TESTING_MODE;
    NSString *deviceID = [[NSUserDefaults standardUserDefaults] objectForKey:@"UDID"];
    NSInteger response = 0;
    
    //check connection to website
    NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@availability.txt", url]]];
    [URLRequest setHTTPMethod:@"GET"];
    NSString *websiteStatus = [[NSString alloc] initWithData:[NSURLConnection sendSynchronousRequest:URLRequest returningResponse:nil error:nil] encoding:NSUTF8StringEncoding];
    if ([websiteStatus isEqualToString:@"available"]) {
        NSString *jsonObjectString = [self encode:(uint8_t *)receipt.bytes length:receipt.length];
        NSString *completeString = [NSString stringWithFormat:@"%@validate_purchase.php?receipt=%@&sandbox=%d&udid=%@", url, jsonObjectString, isSandbox, deviceID];                               
        NSURL *urlForValidation = [NSURL URLWithString:completeString];               
        NSMutableURLRequest *validationRequest = [[NSMutableURLRequest alloc] initWithURL:urlForValidation];                          
        [validationRequest setHTTPMethod:@"GET"];             
        NSData *responseData = [NSURLConnection sendSynchronousRequest:validationRequest returningResponse:nil error:nil];  
        [validationRequest release];
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding: NSUTF8StringEncoding];
        response = [responseString integerValue];
        [responseString release];
    }
    [websiteStatus release];
    [URLRequest release];
    
    if (response==0) {
        //Receipt Valid (or can't connect to aggarwalcreations.com)
        NSLog(@"Valid Receipt");
        [[self upgradeButton] setTitle:@"Purchase Successful" forState:UIControlStateNormal];
        [[NSUserDefaults standardUserDefaults] setValue:receipt forKey:@"sendBigFilesReceipt"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isSendBigFilesPurchased"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase Successful" message:@"You can now transfer files over 5 MB." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        [alert release];
        return YES;
    } else {
        [self hideIndicator];
        [[self upgradeButton] setTitle:@"Error Validating Purchase" forState:UIControlStateNormal];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Validating Purchase" message:@"An error occured while validating your purchase. Please try again. You will only be charged once." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        [alert release];
        return NO;
    }
}

- (NSString *) encode:(const uint8_t *)input length:(NSInteger)length {
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData *data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t *output = (uint8_t *)data.mutableBytes;
    
    for (NSInteger i = 0; i < length; i += 3) {
        NSInteger value = 0;
        for (NSInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger index = (i / 3) * 4;
        output[index + 0] =                    table[(value >> 18) & 0x3F];
        output[index + 1] =                    table[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}

- (IBAction) activatePurchase {
    NSString *deviceID = [[NSUserDefaults standardUserDefaults] objectForKey:@"UDID"];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:deviceID delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert setTag:928];
    [alert release];
}

- (void) requestDidFinish:(SKRequest *)request {
    //[request release];
}

- (void) request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"Failed to connect with error: %@", [error localizedDescription]);
    [[self upgradeButton] setTitle:@"Error Finding Item" forState:UIControlStateNormal];
    [self hideIndicator];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView tag]==928) {
        if([self validatePurchase:nil]) {
            [self cancel:nil];
        }
    }
}

- (void) dealloc {
    [upgradeButton release];
    [cancelButton release];
    [productsRequest setDelegate:nil];
    [productsRequest release];
    [navigationBar release];
    [_product release];
    [super dealloc];
}

@end
