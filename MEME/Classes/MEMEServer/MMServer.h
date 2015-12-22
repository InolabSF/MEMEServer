#import <RoutingHTTPServer/RoutingHTTPServer.h>


#pragma mark - interface
@interface MMServer : RoutingHTTPServer


#pragma mark - class method
+ (MMServer *)sharedInstance;


#pragma mark - api
- (void)start;
- (void)stop;


@end
