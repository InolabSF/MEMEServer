#import <RoutingHTTPServer/RoutingHTTPServer.h>


#define kMEMEServerURL @"http://192.168.1.101:3000/"


#pragma mark - interface
@interface MEMEBridge : RoutingHTTPServer


#pragma mark - class method
+ (MEMEBridge *)sharedInstance;


#pragma mark - api
- (void)start;
- (void)stop;


@end
