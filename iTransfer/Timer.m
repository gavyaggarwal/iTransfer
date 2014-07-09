//
//  Timer.m
//  iTransfer
//
//  Created by Gavy Aggarwal on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Timer.h"

@implementation Timer
@synthesize start = _start;
@synthesize end = _end;
@synthesize speed = _speed;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.start = nil;
        self.end = nil;
    }
    return self;
}

- (void) startTimer {
    self.start = [NSDate date];
}

- (void) stopTimer {
    self.end = [NSDate date];
}

- (double) timeElapsedInSeconds {
    return [self.end timeIntervalSinceDate:self.start];
}

- (void) dealloc {
    NSLog(@"Timer dealloc Called");
    [_start release];
    [_end release];
    [super dealloc];
}

@end
