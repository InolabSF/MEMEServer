#import <RoutingHTTPServer/RoutingHTTPServer.h>


#define kMEMEServerURL @"http://kenzan8000.local:3000/"


#pragma mark - interface
@interface MEMEBridge : RoutingHTTPServer


#pragma mark - class method
+ (MEMEBridge *)sharedInstance;


#pragma mark - api
- (void)start;
- (void)stop;


@end
