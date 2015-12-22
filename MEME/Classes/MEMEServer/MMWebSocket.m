#import "MMWebSocket.h"
#import "HTTPLogging.h"


#pragma mark - implementation
@implementation MMWebSocket


#pragma mark - initialization
/*
- (id)initWithRequest:(HTTPMessage *)aRequest socket:(GCDAsyncSocket *)socket
{
    self = [super initWithRequest:request socket:socket];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(emitNotification:)
                                                     name:@"MMWebSocketEmit"
                                                   object:nil];
    }
    return self;
}
*/

#pragma mark - destruction
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - notification
- (void)emitNotification:(NSNotification *)notification
{
    NSString *message = (NSString *)notification.object;
    if ([message isKindOfClass:[NSString class]]) {
        [self sendMessage:message];
    }
}


#pragma mark - private api
- (void)didOpen
{
	[super didOpen];
    [self sendMessage:@"webSocketDidOpen"];
}

- (void)didReceiveMessage:(NSString *)msg
{
	[self sendMessage:[NSString stringWithFormat:@"%@", [NSDate date]]];
}

- (void)didClose
{
	[self sendMessage:@"webSocketWillClose"];
	[super didClose];
}


@end
