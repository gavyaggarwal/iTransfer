#import "WebServer.h"
#import "UDID.h"
#import "Reachability.h"

static NSString* _serverName = nil;
static dispatch_queue_t _connectionQueue = NULL;
static NSInteger _connectionCount = 0;

@implementation WebServerConnection

- (void) open {
    [super open];
    
    dispatch_sync(_connectionQueue, ^{
        //DCHECK(_connectionCount >= 0);
        /*if (_connectionCount == 0) {
            WebServer* server = (WebServer*)self.server;
            dispatch_async(dispatch_get_main_queue(), ^{
                [server.delegate webServerConnected:server];
            });
        }*/
        _connectionCount += 1;
    });
}

- (void) close {
    dispatch_sync(_connectionQueue, ^{
        //DCHECK(_connectionCount > 0);
        _connectionCount -= 1;
        /*if (_connectionCount == 0) {
            WebServer* server = (WebServer*)self.server;
            dispatch_async(dispatch_get_main_queue(), ^{
                [server.delegate webServerDisconnected:server];
            });
        }*/
    });
    
    [super close];
}

@end

@implementation WebServer

@synthesize delegate=_delegate;

+ (void) initialize {
    if (_serverName == nil) {
        _serverName = [[NSString alloc] initWithFormat:NSLocalizedString(@"SERVER_NAME_FORMAT", nil),
                       [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                       [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
    }
    if (_connectionQueue == NULL) {
        _connectionQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    }
}

+ (Class) connectionClass {
    return [WebServerConnection class];
}

+ (NSString*) serverName {
    return _serverName;
}

- (BOOL) start {
    if([[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] != ReachableViaWiFi) {
        [self.delegate webServerFailed:self];
        return NO;
    }
    NSString* websitePath = [[NSBundle mainBundle] pathForResource:@"Website" ofType:nil];
    NSString* footer = [NSString stringWithFormat:NSLocalizedString(@"SERVER_FOOTER_FORMAT", nil),
                        [[UIDevice currentDevice] name],
                        [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    NSDictionary* baseVariables = [NSDictionary dictionaryWithObjectsAndKeys:footer, @"footer", nil];
    
    [self addHandlerForBasePath:@"/" localPath:websitePath indexFilename:nil cacheAge:3600];
    
    [self addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        // Called from GCD thread
        return [GCDWebServerResponse responseWithRedirect:[NSURL URLWithString:@"index.html" relativeToURL:request.URL] permanent:NO];
        
    }];
    [self addHandlerForMethod:@"GET" path:@"/index.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        // Called from GCD thread
        NSMutableDictionary* variables = [NSMutableDictionary dictionaryWithDictionary:baseVariables];
        [variables setObject:UIDevice.currentDevice.name forKey:@"devicename"];
        [variables setObject:[NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"] forKey:@"appversion"];
        
        //Get list of files
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSArray *files = [NSFileManager.defaultManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
        NSMutableString *content = [[NSMutableString alloc] init];
        for (NSString *file in files) {
            NSString *filepath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, file];
            NSDictionary *attrs = [NSFileManager.defaultManager attributesOfItemAtPath:filepath error:nil];
            NSString *fileSize = [UDID getFormattedFileSize:[attrs fileSize]];
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setTimeZone:[NSTimeZone localTimeZone]];
            [df setDateFormat:@"MMMM dd, YYYY"];
            NSString *fileDate = [df stringFromDate:[attrs fileModificationDate]];
            [content appendFormat:@"<tr><td><a href='download?file=%@'>%@</a></td><td>%@</td><td>%@</td></tr>\n", file, file, fileSize, fileDate];
            [df release];
        }
        [variables setObject:content forKey:@"content"];
        [content release];
        return [GCDWebServerDataResponse responseWithHTMLTemplate:[websitePath stringByAppendingPathComponent:request.path] variables:variables];
        
    }];
    [self addHandlerForMethod:@"GET" path:@"/download" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        
        // Called from GCD thread
        GCDWebServerResponse* response = nil;
        NSString *fileName = [request.query objectForKey:@"file"];
        NSLog(@"Client Requested to Download File: %@", fileName);
        NSString *path = [NSString stringWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], fileName];
        if (path) {
            response = [GCDWebServerFileResponse responseWithFile:path isAttachment:YES];
            
            /*dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate webServerDidDownloadComic:self];
            });*/
        }
        return response;
        
    }];
    
    if (![self startWithPort:8080 bonjourName:@""]) {
        [self removeAllHandlers];
        return NO;
    }
    
    [self.delegate webServerStarted:self];
    
    return YES;
}

- (void) stop {
    [super stop];
    
    [self removeAllHandlers];  // Required to break release cycles (since handler blocks can hold references to server)
    
    [self.delegate webServerStopped:self];
}

@end
