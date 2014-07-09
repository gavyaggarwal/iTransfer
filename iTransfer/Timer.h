//
//  Timer.h
//  iTransfer
//
//  Created by Gavy Aggarwal on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Timer : NSObject {
    NSDate *start;
    NSDate *end;
    int speed;
}

@property (retain) NSDate *start;
@property (retain) NSDate *end;
@property (assign) int speed;

- (void) startTimer;
- (void) stopTimer;
- (double) timeElapsedInSeconds;

@end
