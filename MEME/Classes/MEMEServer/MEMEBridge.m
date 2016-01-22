#import "MEMEBridge.h"
#import <MEMELib/MEMELib.h>

#if TARGET_OS_IPHONE

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000 // iOS 6.0 or later
#define NEEDS_DISPATCH_RETAIN_RELEASE 0
#else                                        // iOS 5.X or earlier
#define NEEDS_DISPATCH_RETAIN_RELEASE 1
#endif

#else

#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1080    // Mac OS X 10.8 or later
#define NEEDS_DISPATCH_RETAIN_RELEASE 0
#else
#define NEEDS_DISPATCH_RETAIN_RELEASE 1 // Mac OS X 10.7 or earlier
#endif

#endif

#pragma mark - interface
@interface MEMEBridge() <MEMELibDelegate> {
    dispatch_queue_t _synchronizationQueue;
    BOOL _authorizationPending;
    BOOL _authorized;
}

#pragma mark - property

@property (nonatomic, strong) NSMutableArray *peripherals;
@property (nonatomic, copy) NSString *clientID;
@property (nonatomic, copy) NSString *clientSecret;

@end


#pragma mark - implementation
@implementation MEMEBridge


#pragma mark - Peripheral Queue management

- (BOOL) addPeripheralIfNew:(CBPeripheral *)peripheral
{
    __block BOOL result = NO;
    dispatch_sync(_synchronizationQueue, ^{
        BOOL peripheralInList = NO;
        for (CBPeripheral *p in self.peripherals){
            if ([p.identifier isEqual:peripheral.identifier]) {
                peripheralInList = YES;
                break;
            }
        }
        
        if ((result = !peripheralInList))  {
            [self.peripherals addObject:peripheral];
        }
    });
    return result;
}

- (CBPeripheral *) findPeripheral:(NSString *)uuid
{
    __block CBPeripheral *result = nil;
    dispatch_sync(_synchronizationQueue, ^{
        for (CBPeripheral *peripheral in self.peripherals) {
            if ([uuid isEqualToString:[peripheral.identifier UUIDString]]) {
                result = peripheral;
                break;
            }
        }
    });
    return result;
}

#pragma mark - Authorization

- (BOOL) isAuthorizationPending
{
    __block BOOL result = NO;
    dispatch_sync(_synchronizationQueue, ^{
        result = _authorizationPending;
    });
    return result;
}

- (void) setAuthorizedPending:(BOOL)authorizedPending
{
    dispatch_sync(_synchronizationQueue, ^{
        _authorizationPending = authorizedPending;
    });
}

- (BOOL) isAuthorized
{
    __block BOOL result = NO;
    dispatch_sync(_synchronizationQueue, ^{
        result = _authorized;
    });
    return result;
}

- (void) setAuthorized:(BOOL)authorized
{
    dispatch_sync(_synchronizationQueue, ^{
        _authorized = authorized;
    });
}

#pragma mark - Server routes and handlers

- (void) serverAddInitialRoutes
{
    [self get:@"/setAppClientId:clientSecret" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        NSString *appClientId = request.params[@"arg0"];
        NSString *clientSecret = request.params[@"arg1"];
        BOOL same = [self.clientID isEqualToString:appClientId] && [self.clientSecret isEqualToString:clientSecret];
        
        if ([self isAuthorizationPending]) {
            if (!same) {
                [response setStatusCode:400];
            }
            [response respondWithString:@"SDK authorization already pending"];
        }
        else if ([self isAuthorized]) {
            if (!same) {
                [response setStatusCode:400];
            }
            [response respondWithString:@"SDK already authorized"];
        }
        else {
            self.clientID = appClientId;
            self.clientSecret = clientSecret;
            [self setAuthorizedPending:YES];
            [MEMELib setAppClientId:appClientId clientSecret:clientSecret];
            [response respondWithString:@"void"];
            [[MEMELib sharedInstance] setDelegate:self];
        }
    }];
}

- (void) serverAddAuthorizedRoutes
{
    [self get:@"/isConnected" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        BOOL isConnected = [[MEMELib sharedInstance] isConnected];
        [response respondWithString:[NSString stringWithFormat:@"%@", @(isConnected)]];
    }];
    [self get:@"/isDataReceiving" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        BOOL isDataReceiving = [[MEMELib sharedInstance] isDataReceiving];
        [response respondWithString:[NSString stringWithFormat:@"%@", @(isDataReceiving)]];
    }];
    [self get:@"/isCalibrated" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        MEMECalibStatus isCalibrated = [[MEMELib sharedInstance] isCalibrated];
        [response respondWithString:[NSString stringWithFormat:@"%@", @(isCalibrated)]];
    }];
    [self get:@"/setAppClientId:clientSecret" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        NSString *appClientId = request.params[@"arg0"];
        NSString *clientSecret = request.params[@"arg1"];
        [MEMELib setAppClientId:appClientId clientSecret:clientSecret];
        [response respondWithString:@"void"];
        [[MEMELib sharedInstance] setDelegate:self];
    }];
    [self get:@"/startScanningPeripherals" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        MEMEStatus status = [[MEMELib sharedInstance] startScanningPeripherals];
        [response respondWithString:[NSString stringWithFormat:@"%@", @(status)]];
    }];
    [self get:@"/stopScanningPeripherals" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        MEMEStatus status = [[MEMELib sharedInstance] stopScanningPeripherals];
        [response respondWithString:[NSString stringWithFormat:@"%@", @(status)]];
    }];
    [self get:@"/connectPeripheral" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        CBPeripheral *peripheral = [self findPeripheral:request.params[@"arg0"]];
        // Can only connect if previously seen
        if (peripheral != nil) {
            MEMEStatus status = [[MEMELib sharedInstance] connectPeripheral:peripheral];
            [response respondWithString:[NSString stringWithFormat:@"%@", @(status)]];
            //dispatch_async(connectionQueue, ^{ [response respondWithString:[NSString stringWithFormat:@"%@", @(status)]]; });
        }
        else {
            NSLog(@"Attempt to connect previously unseen peripheral");
        }
    }];
    [self get:@"/disconnectPeripheral" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        MEMEStatus status = [[MEMELib sharedInstance] disconnectPeripheral];
        [response respondWithString:[NSString stringWithFormat:@"%@", @(status)]];
    }];
    [self get:@"/getConnectedByOthers" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        NSArray *connectedOthers = [[MEMELib sharedInstance] getConnectedByOthers];
        NSString *uuids = @"";
        for (CBPeripheral *peripheral in connectedOthers) {
            uuids = [uuids stringByAppendingString:[peripheral.identifier UUIDString]];
            uuids = [uuids stringByAppendingString:@","];
        }
        [response respondWithString:[NSString stringWithFormat:@"%@", uuids]];
    }];
    [self get:@"/startDataReport" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        MEMEStatus status = [[MEMELib sharedInstance] startDataReport];
        [response respondWithString:[NSString stringWithFormat:@"%@", @(status)]];
    }];
    [self get:@"/stopDataReport" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        MEMEStatus status = [[MEMELib sharedInstance] stopDataReport];
        [response respondWithString:[NSString stringWithFormat:@"%@", @(status)]];
    }];
    [self get:@"/getSDKVersion" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        NSString *SDKVersion = [[MEMELib sharedInstance] getSDKVersion];
        [response respondWithString:SDKVersion];
    }];
    [self get:@"/getFWVersion" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        NSString *FWVersion = [[MEMELib sharedInstance] getFWVersion];
        [response respondWithString:FWVersion];
    }];
    [self get:@"/getHWVersion" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        UInt8 HWVersion = [[MEMELib sharedInstance] getHWVersion];
        [response respondWithString:[NSString stringWithFormat:@"%@", @(HWVersion)]];
    }];
    [self get:@"/getConnectedDeviceType" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        int connectedDeviceType = [[MEMELib sharedInstance] getConnectedDeviceType];
        [response respondWithString:[NSString stringWithFormat:@"%@", @(connectedDeviceType)]];
    }];
    [self get:@"/getConnectedDeviceSubType" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSLog(@"Server received %@", request.url);
        int connectedDeviceSubType = [[MEMELib sharedInstance] getConnectedDeviceSubType];
        [response respondWithString:[NSString stringWithFormat:@"%@", @(connectedDeviceSubType)]];
    }];
    
    // Delegate test
    [self get:@"/memeAppAuthorized" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        [self requestDelegate:@"memeAppAuthorized" arguments:@[@"0"]];
    }];
    [self get:@"/memeFirmwareAuthorized" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        [self requestDelegate:@"memeFirmwareAuthorized" arguments:@[@"0"]];
    }];
    [self get:@"/memePeripheralFound:withDeviceAddress" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        [self requestDelegate:@"memePeripheralFound:withDeviceAddress" arguments:@[@"398315C3-0734-400E-9639-6490BAD79086", @"address"]];
    }];
    [self get:@"/memePeripheralConnected" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        [self requestDelegate:@"memePeripheralConnected" arguments:@[@"398315C3-0734-400E-9639-6490BAD79086"]];
    }];
    [self get:@"/memePeripheralDisconnected" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        [self requestDelegate:@"memePeripheralDisconnected" arguments:@[@"398315C3-0734-400E-9639-6490BAD79086"]];
    }];
    [self get:@"/memeRealTimeModeDataReceived" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        NSArray *realTimeData = @[
                                  @"1",
                                  @"2",
                                  @"3",
                                  @"4",
                                  @"5",
                                  @"6",
                                  @"7",
                                  @"8",
                                  @"9",
                                  @"0.1",
                                  @"0.2",
                                  @"0.3",
                                  @"1",
                                  @"2",
                                  @"3",
                                  ];
        [self requestDelegate:@"memeRealTimeModeDataReceived" arguments:realTimeData];
    }];
    [self get:@"/memeCommandResponse" withBlock:^ (RouteRequest *request, RouteResponse *response) {
        [self requestDelegate:@"memeCommandResponse" arguments:@[@"0",@"1"]];
    }];
}

#pragma mark - class method
+ (MEMEBridge *)sharedInstance
{
    static MEMEBridge *server  = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        server = [[MEMEBridge alloc] init];
    });
    return server;
}

#pragma mark - initialization
- (id)init
{
    self = [super init];
    if (self) {
        _authorizationPending = NO;
        _authorized = NO;
        _peripherals = @[].mutableCopy;
        _synchronizationQueue = dispatch_queue_create("MEMEBridge.peripheralManagingQueue", DISPATCH_QUEUE_SERIAL);
        _clientID = nil;
        _clientSecret = nil;

        // server
        [self setPort:3000];
        [self setDefaultHeader:@"content-type" value:@"application/json"];

        [self serverAddInitialRoutes];
    }
    return self;
}


#pragma mark - destruction
- (void)dealloc
{
#if NEEDS_DISPATCH_RETAIN_RELEASE
    dispatch_release(peripheralManagingQueue);
#endif
}

#pragma mark - MEMELibDelegate

- (void)memePeripheralFound:(CBPeripheral *)peripheral
          withDeviceAddress:(NSString *)address
{
    NSLog(@"Server delegate called memePeripheralFound: %@", peripheral.identifier);
    [self addPeripheralIfNew:peripheral];
    [self requestDelegate:@"memePeripheralFound:withDeviceAddress"
                arguments:@[[peripheral.identifier UUIDString], address]];
}

- (void)memePeripheralConnected:(CBPeripheral *)peripheral
{
    NSLog(@"Server delegate called memePeripheralConnected: %@", peripheral.identifier);
    [self requestDelegate:@"memePeripheralConnected"
                arguments:@[[peripheral.identifier UUIDString]]];
}

- (void)memePeripheralDisconnected:(CBPeripheral *)peripheral
{
    NSLog(@"Server delegate called memePeripheralDisconnected: %@", peripheral.identifier);
    [self requestDelegate:@"memePeripheralDisconnected"
                arguments:@[[peripheral.identifier UUIDString]]];
}

- (void)memeRealTimeModeDataReceived:(MEMERealTimeData *)data
{
    NSLog(@"Server delegate called realTimeModeDataReceived");
    NSArray *realTimeData = @[
        [NSString stringWithFormat:@"%@", @(data.fitError)],
        [NSString stringWithFormat:@"%@", @(data.isWalking)],
        [NSString stringWithFormat:@"%@", @(data.powerLeft)],
        [NSString stringWithFormat:@"%@", @(data.eyeMoveUp)],
        [NSString stringWithFormat:@"%@", @(data.eyeMoveDown)],
        [NSString stringWithFormat:@"%@", @(data.eyeMoveLeft)],
        [NSString stringWithFormat:@"%@", @(data.eyeMoveRight)],
        [NSString stringWithFormat:@"%@", @(data.blinkSpeed)],
        [NSString stringWithFormat:@"%@", @(data.blinkStrength)],
        [NSString stringWithFormat:@"%@", @(data.roll)],
        [NSString stringWithFormat:@"%@", @(data.pitch)],
        [NSString stringWithFormat:@"%@", @(data.yaw)],
        [NSString stringWithFormat:@"%@", @(data.accX)],
        [NSString stringWithFormat:@"%@", @(data.accY)],
        [NSString stringWithFormat:@"%@", @(data.accZ)],
    ];
    [self requestDelegate:@"memeRealTimeModeDataReceived"
                arguments:realTimeData];
}

- (void)memeAppAuthorized:(MEMEStatus)status
{
    NSLog(@"Server delegate called memeAppAuthorized");
    if (status == MEME_OK) {
        [self setAuthorized:YES];
        [self setAuthorizedPending:NO];
        [self serverAddAuthorizedRoutes];
    }
    [self requestDelegate:@"memeAppAuthorized"
                arguments:@[[NSString stringWithFormat:@"%@", @(status)]]];
}

- (void)memeCommandResponse:(MEMEResponse)response
{
    NSLog(@"Server delegate called memeCommandResponse: %d/%@", response.eventCode, @(response.commandResult));
    NSArray *r = @[
        [NSString stringWithFormat:@"%@", @(response.eventCode)],
        [NSString stringWithFormat:@"%@", @(response.commandResult)],
    ];
    [self requestDelegate:@"memeCommandResponse"
                arguments:r];
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


#pragma mark - private api
- (id)requestDelegate:(NSString *)delegate
            arguments:(NSArray *)arguments
{
    NSMutableArray *queryItems = @[].mutableCopy;
    for (int i = 0; i < [arguments count]; i++) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:[NSString stringWithFormat:@"arg%d", i] value:arguments[i]]];
    }
    NSURLComponents *URLComponents = [NSURLComponents componentsWithString:[NSString stringWithFormat:@"%@%@", kMEMEServerURL, delegate]];
    URLComponents.queryItems = queryItems;

    NSMutableURLRequest *req = [NSMutableURLRequest new];
    [req setURL:URLComponents.URL];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSError *error = nil;
    [NSURLConnection sendSynchronousRequest:req
                          returningResponse:nil
                                      error:&error];
    if (error) {
        NSLog(@"!!!!!!!!!!!!!!!\ndelegate:%@\narguments:%@\nerror:%@", delegate, arguments, error);
    }

    return nil;
}


@end
