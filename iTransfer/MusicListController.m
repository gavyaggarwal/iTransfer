//
//  MusicListController.m
//  iTransfer
//
//  Created by Gavy Aggarwal on 6/12/13.
//
//

#import "MusicListController.h"

@interface MusicListController ()

@end

@implementation MusicListController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSLog(@"MusicListController init Called");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"MusicListController init Called");
    [self setTitle:@"Music Center"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
