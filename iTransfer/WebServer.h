
#import "GCDWebServerConnection.h"

@class WebServer;

@protocol WebServerDelegate <NSObject>
- (void) webServerStarted:(WebServer*)server;
- (void) webServerFailed:(WebServer *)server;
- (void) webServerStopped:(WebServer*)server;
@end

@interface WebServer : GCDWebServer {
@private
  id<WebServerDelegate> _delegate;
}
@property(nonatomic, assign) id<WebServerDelegate> delegate;
@end

@interface WebServerConnection : GCDWebServerConnection
@end
