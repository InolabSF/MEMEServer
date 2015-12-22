#import "MMServer.h"
#import <MEMELib/MEMELib.h>
#import "MMHTTPConnection.h"


#pragma mark - implementation
@implementation MMServer


#pragma mark - class method
+ (MMServer *)sharedInstance
{
    static MMServer *server  = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        server = [[MMServer alloc] init];
    });
    return server;
}


#pragma mark - initialization
- (id)init
{
    self = [super init];
    if (self) {
        // server
	    [self setConnectionClass:[MMHTTPConnection class]];
	    [self setType:@"_http._tcp."];
        [self setPort:3000];
        [self setDefaultHeader:@"content-type" value:@"application/json"];
    }
    return self;
}

#pragma mark - public api
- (void)start
{
    NSError *error;
    if (![self start:&error]) {
    }
}

- (void)stop
{
    [super stop];
}


@end
