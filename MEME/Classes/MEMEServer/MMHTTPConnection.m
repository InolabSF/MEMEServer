#import "MMHTTPConnection.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "GCDAsyncSocket.h"
#import <MEMELib/MEMELib.h>
#import "MMWebSocket.h"



#pragma mark - interface
@interface MMHTTPConnection() <MEMELibDelegate>

#pragma mark - property
@property (nonatomic, strong) NSMutableArray *peripherals;
//@property (nonatomic, strong) MMWebSocket *webSocket;


@end


#pragma mark - implementation
@implementation MMHTTPConnection


#pragma mark - initialization
- (id)initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig
{
    self = [super initWithAsyncSocket:newSocket configuration:aConfig];
    if (self) {
        self.peripherals = @[].mutableCopy;
    }
    return self;
}


/*
#pragma mark - WebSocketDelegate
- (void)webSocketDidOpen:(WebSocket *)ws
{
}

- (void)webSocket:(WebSocket *)ws didReceiveMessage:(NSString *)msg
{
}

- (void)webSocketDidClose:(WebSocket *)ws
{
}
*/


#pragma mark - MEMELibDelegate
- (void)memePeripheralFound:(CBPeripheral *)peripheral
          withDeviceAddress:(NSString *)address
{
    BOOL alreadyFound = NO;
    for (CBPeripheral *p in self.peripherals){
        if ([p.identifier isEqual:peripheral.identifier]){
            alreadyFound = YES;
            break;
        }
    }

    if (!alreadyFound)  {
        [self.peripherals addObject:peripheral];
        NSMutableArray *uuids = @[].mutableCopy;
        for (CBPeripheral *peripheral in self.peripherals) {
            [uuids addObject:[peripheral.identifier UUIDString]];
        }
        [self sendWebSocketMessage:@{@"delegate":@"memePeripheralFound:withDeviceAddress:", @"args":@[[peripheral.identifier UUIDString], address]}];
    }
}

- (void)memePeripheralConnected:(CBPeripheral *)peripheral
{
    [[MEMELib sharedInstance] startDataReport];
    [self sendWebSocketMessage:@{@"delegate":@"memePeripheralConnected:", @"args":@[[peripheral.identifier UUIDString]]}];
}

- (void)memePeripheralDisconnected:(CBPeripheral *)peripheral
{
    [self sendWebSocketMessage:@{@"delegate":@"memePeripheralDisconnected:", @"args":@[[peripheral.identifier UUIDString]]}];
}

- (void)memeRealTimeModeDataReceived:(MEMERealTimeData *)data
{
    NSDictionary *realTimeData = @{
        @"fitError":@(data.fitError),
       @"isWalking":@(data.isWalking),
       @"powerLeft":@(data.powerLeft),
       @"eyeMoveUp":@(data.eyeMoveUp),
     @"eyeMoveDown":@(data.eyeMoveDown),
     @"eyeMoveLeft":@(data.eyeMoveLeft),
    @"eyeMoveRight":@(data.eyeMoveRight),
      @"blinkSpeed":@(data.blinkSpeed),
   @"blinkStrength":@(data.blinkStrength),
            @"roll":@(data.roll),
           @"pitch":@(data.pitch),
             @"yaw":@(data.yaw),
            @"accX":@(data.accX),
            @"accY":@(data.accY),
            @"accZ":@(data.accZ),
    };
    [self sendWebSocketMessage:@{@"delegate":@"memeRealTimeModeDataReceived:", @"args":@[realTimeData],}];
}

- (void)memeAppAuthorized:(MEMEStatus)status
{
    [self sendWebSocketMessage:@{@"delegate":@"memeAppAuthorized:", @"args":@[@(status)],}];
}

- (void)memeCommandResponse:(MEMEResponse)response
{
    NSDictionary *r = @{
        @"eventCode":@(response.eventCode),
    @"commandResult":@(response.commandResult),
    };
    [self sendWebSocketMessage:@{@"delegate":@"memeCommandResponse:", @"args":@[r],}];
}


#pragma mark - private api
/**
 * call MEMELib API from request
 * @return response
 **/
- (NSObject<HTTPResponse> *)response
{
    NSURL *url = [request url];
    NSString *path = nil;
    NSString *query = nil;
    NSDictionary *params = [NSDictionary dictionary];
    if (url) {
        path = [url path];
        query = [url query];
        if (query) {
            params = [self parseParams:query];
        }
    }
    HTTPDataResponse *response = nil;
    NSDictionary *body = nil;

    // MEMELib APIs
    if ([path isEqualToString:@"/isConnected"]) {
        BOOL isConnected = [[MEMELib sharedInstance] isConnected];
        body = @{@"api":@"isConnected", @"return":@(isConnected),};
    }
    else if ([path isEqualToString:@"/isDataReceiving"]) {
        BOOL isDataReceiving = [[MEMELib sharedInstance] isDataReceiving];
        body = @{@"api":@"isDataReceiving", @"return":@(isDataReceiving),};
    }
    else if ([path isEqualToString:@"/isCalibrated"]) {
        BOOL isCalibrated = [[MEMELib sharedInstance] isCalibrated];
        body = @{@"api":@"isCalibrated", @"return":@(isCalibrated),};
    }
    else if ([path isEqualToString:@"/set"]) {
        NSString *appClientId = params[@"appClientId"];
        NSString *clientSecret = params[@"clientSecret"];
        if ([appClientId isKindOfClass:[NSString class]] && [clientSecret isKindOfClass:[NSString class]]) {
            [MEMELib setAppClientId:appClientId clientSecret:clientSecret];
            body = @{@"api":@"setAppClientId:clientSecret:", @"return":@"void",};
        }
    }
    else if ([path isEqualToString:@"/startScanningPeripherals"]) {
        MEMEStatus status = [[MEMELib sharedInstance] startScanningPeripherals];
        body = @{@"api":@"startScanningPeripherals:", @"return":@(status),};
    }
    else if ([path isEqualToString:@"/stopScanningPeripherals"]) {
        MEMEStatus status = [[MEMELib sharedInstance] startScanningPeripherals];
        body = @{@"api":@"startScanningPeripherals:", @"return":@(status),};
    }
    else if ([path isEqualToString:@"/connect"]) {
        NSString *uuid = params[@"peripheral"];
        CBPeripheral *p = nil;
        for (CBPeripheral *peripheral in self.peripherals) {
            if ([uuid isEqualToString:[peripheral.identifier UUIDString]]) {
                p = peripheral;
                break;
            }
        }
        if (p) {
            MEMEStatus status = [[MEMELib sharedInstance] connectPeripheral:p];
            body = @{@"api":@"connectPeripheral:", @"return":@(status),};
        }
    }
    else if ([path isEqualToString:@"/disconnectPeripheral"]) {
        MEMEStatus status = [[MEMELib sharedInstance] disconnectPeripheral];
        body = @{@"api":@"disconnectPeripheral", @"return":@(status),};
    }
    else if ([path isEqualToString:@"/getConnectedByOthers"]) {
        NSArray *connectedOthers = [[MEMELib sharedInstance] getConnectedByOthers];
        NSMutableArray *uuids = @[].mutableCopy;
        for (CBPeripheral *peripheral in connectedOthers) {
            [uuids addObject:[peripheral.identifier UUIDString]];
        }
        body = @{@"api":@"getConnectedByOthers", @"return":uuids,};
    }
    else if ([path isEqualToString:@"/startDataReport"]) {
        MEMEStatus status = [[MEMELib sharedInstance] startDataReport];
        body = @{@"api":@"startDataReport", @"return":@(status),};
    }
    else if ([path isEqualToString:@"/stopDataReport"]) {
        MEMEStatus status = [[MEMELib sharedInstance] stopDataReport];
        body = @{@"api":@"stopDataReport", @"return":@(status),};
    }
    else if ([path isEqualToString:@"/getSDKVersion"]) {
        NSString *SDKVersion = [[MEMELib sharedInstance] getSDKVersion];
        body = @{@"api":@"getSDKVersion", @"return":SDKVersion,};
    }
    else if ([path isEqualToString:@"/getFWVersion"]) {
        NSString *FWVersion = [[MEMELib sharedInstance] getFWVersion];
        body = @{@"api":@"getFWVersion", @"return":FWVersion};
    }
    else if ([path isEqualToString:@"/getHWVersion"]) {
        UInt8 HWVersion = [[MEMELib sharedInstance] getHWVersion];
        body = @{@"api":@"getHWVersion", @"return":@(HWVersion)};
    }
    else if ([path isEqualToString:@"/getConnectedDeviceType"]) {
        int connectedDeviceType = [[MEMELib sharedInstance] getConnectedDeviceType];
        body = @{@"api":@"getConnectedDeviceType", @"return":@(connectedDeviceType)};
    }
    else if ([path isEqualToString:@"/getConnectedDeviceSubType"]) {
        int connectedDeviceSubType = [[MEMELib sharedInstance] getConnectedDeviceSubType];
        body = @{@"api":@"getConnectedDeviceSubType", @"return":@(connectedDeviceSubType)};
    }
    /*
    //
    else if ([path isEqualToString:@"/memeAppAuthorized:"]) {
        [self sendWebSocketMessage:@{@"delegate":@"memeAppAuthorized:", @"args":@[@(0)],}];
    }
    else if ([path isEqualToString:@"/memeFirmwareAuthorized:"]) {
        [self sendWebSocketMessage:@{@"delegate":@"memeFirmwareAuthorized:", @"args":@[@(0)],}];
    }
    else if ([path isEqualToString:@"/memePeripheralFound:withDeviceAddress:"]) {
        [self sendWebSocketMessage:@{@"delegate":@"memePeripheralFound:withDeviceAddress:", @"args":@[@"398315C3-0734-400E-9639-6490BAD79086", @"address"],}];
    }
    else if ([path isEqualToString:@"/memePeripheralConnected:"]) {
        [self sendWebSocketMessage:@{@"delegate":@"memePeripheralConnected:", @"args":@[@"398315C3-0734-400E-9639-6490BAD79086"],}];
    }
    else if ([path isEqualToString:@"/memePeripheralDisconnected:"]) {
        [self sendWebSocketMessage:@{@"delegate":@"memePeripheralDisconnected:", @"args":@[@"398315C3-0734-400E-9639-6490BAD79086"],}];
    }
    else if ([path isEqualToString:@"/memeRealTimeModeDataReceived:"]) {
        NSDictionary *realTimeData = @{
                                       @"fitError":@(1),
                                       @"isWalking":@(2),
                                       @"powerLeft":@(3),
                                       @"eyeMoveUp":@(4),
                                       @"eyeMoveDown":@(5),
                                       @"eyeMoveLeft":@(6),
                                       @"eyeMoveRight ":@(7),
                                       @"blinkSpeed":@(8),
                                       @"blinkStrength":@(9),
                                       @"roll":@(0.1),
                                       @"pitch":@(0.2),
                                       @"yaw":@(0.3),
                                       @"accX":@(1),
                                       @"accY":@(2),
                                       @"accZ":@(3),
        };
        [self sendWebSocketMessage:@{@"delegate":@"memeRealTimeModeDataReceived:", @"args":@[realTimeData],}];
    }
    else if ([path isEqualToString:@"/memeCommandResponse:"]) {
        [self sendWebSocketMessage:@{@"delegate":@"memeCommandResponse:", @"args":@[@{@"eventCode":@(0), @"commandResult":@(TRUE),}],}];
    }
    //
    */

    if (body) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:body
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
        response = [[HTTPDataResponse alloc] initWithData:data];
    }
    return response;
}

/**
 * emit webSocket
 * @param json message Dictionary
 **/
- (void)sendWebSocketMessage:(NSDictionary *)message
{
    NSData *data = [NSJSONSerialization dataWithJSONObject:message
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:nil];
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"MMWebSocketEmit"
                                                        object:msg
                                                      userInfo:@{}];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    NSObject<HTTPResponse> *response = [self response];
    if (!response) {
        response = [super httpResponseForMethod:method URI:path];
    }
    return response;
}

- (WebSocket *)webSocketForURI:(NSString *)path
{
    if ([path isEqualToString:@"/"]) {
        MMWebSocket *socket = [[MMWebSocket alloc] initWithRequest:request socket:asyncSocket];
        [[NSNotificationCenter defaultCenter] addObserver:socket
                                                 selector:@selector(emitNotification:)
                                                     name:@"MMWebSocketEmit"
                                                   object:nil];
        return socket;
    }
    return [super webSocketForURI:path];
}


@end
