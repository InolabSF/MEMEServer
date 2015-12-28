#import "MEMEBridge.h"
#import <MEMELib/MEMELib.h>
//#import "MMHTTPConnection.h"


#pragma mark - interface
@interface MEMEBridge() <MEMELibDelegate> {
    dispatch_queue_t peripheralManagingQueue;
    dispatch_group_t peripheralManagingGroup;

}

#pragma mark - property
@property (nonatomic, strong) NSMutableArray *peripherals;

@end


#pragma mark - implementation
@implementation MEMEBridge


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
        self.peripherals = @[].mutableCopy;
        peripheralManagingGroup = dispatch_group_create();
        peripheralManagingQueue = dispatch_queue_create("MEMEBridge.peripheralManagingQueue", NULL);

        // server
        [self setPort:3000];
        [self setDefaultHeader:@"content-type" value:@"application/json"];

        // MEMELib APIs
        __block __unsafe_unretained typeof(self) bself = self;
        [self get:@"/isConnected" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            BOOL isConnected = [[MEMELib sharedInstance] isConnected];
            [response respondWithString:[NSString stringWithFormat:@"%@", @(isConnected)]];
        }];
        [self get:@"/isDataReceiving" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            BOOL isDataReceiving = [[MEMELib sharedInstance] isDataReceiving];
            [response respondWithString:[NSString stringWithFormat:@"%@", @(isDataReceiving)]];
        }];
        [self get:@"/isCalibrated" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            BOOL isCalibrated = [[MEMELib sharedInstance] isCalibrated];
            [response respondWithString:[NSString stringWithFormat:@"%@", @(isCalibrated)]];
        }];
        [self get:@"/setAppClientId:clientSecret:" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            NSString *appClientId = request.params[@"arg0"];
            NSString *clientSecret = request.params[@"arg1"];
            [MEMELib setAppClientId:appClientId clientSecret:clientSecret];
            [response respondWithString:@"void"];
            [[MEMELib sharedInstance] setDelegate:bself];
        }];
        [self get:@"/startScanningPeripherals" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            MEMEStatus status = [[MEMELib sharedInstance] startScanningPeripherals];
            [response respondWithString:[NSString stringWithFormat:@"%@", @(status)]];
        }];
        [self get:@"/stopScanningPeripherals" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            MEMEStatus status = [[MEMELib sharedInstance] startScanningPeripherals];
            [response respondWithString:[NSString stringWithFormat:@"%@", @(status)]];
        }];
        [self get:@"/connectPeripheral:" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            dispatch_group_enter(peripheralManagingGroup);
            dispatch_async(peripheralManagingQueue, ^{

            NSString *uuid = request.params[@"arg0"];
            CBPeripheral *p = nil;
            for (CBPeripheral *peripheral in bself.peripherals) {
                if ([uuid isEqualToString:[peripheral.identifier UUIDString]]) {
                    p = peripheral;
                    break;
                }
            }
            if (p) {
                MEMEStatus status = [[MEMELib sharedInstance] connectPeripheral:p];
                dispatch_group_leave(peripheralManagingGroup);
                dispatch_async(connectionQueue, ^{ [response respondWithString:[NSString stringWithFormat:@"%@", @(status)]]; });
            }

            });
        }];
        [self get:@"/disconnectPeripheral" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            MEMEStatus status = [[MEMELib sharedInstance] disconnectPeripheral];
            [response respondWithString:[NSString stringWithFormat:@"%@", @(status)]];
        }];
        [self get:@"/getConnectedByOthers" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            NSArray *connectedOthers = [[MEMELib sharedInstance] getConnectedByOthers];
            NSString *uuids = @"";
            for (CBPeripheral *peripheral in connectedOthers) {
                uuids = [uuids stringByAppendingString:[peripheral.identifier UUIDString]];
                uuids = [uuids stringByAppendingString:@","];
            }
            [response respondWithString:[NSString stringWithFormat:@"%@", uuids]];
        }];
        [self get:@"/startDataReport" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            MEMEStatus status = [[MEMELib sharedInstance] startDataReport];
            [response respondWithString:[NSString stringWithFormat:@"%@", @(status)]];
        }];
        [self get:@"/stopDataReport" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            MEMEStatus status = [[MEMELib sharedInstance] stopDataReport];
            [response respondWithString:[NSString stringWithFormat:@"%@", @(status)]];
        }];
        [self get:@"/getSDKVersion" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            NSString *SDKVersion = [[MEMELib sharedInstance] getSDKVersion];
            [response respondWithString:SDKVersion];
        }];
        [self get:@"/getFWVersion" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            NSString *FWVersion = [[MEMELib sharedInstance] getFWVersion];
            [response respondWithString:FWVersion];
        }];
        [self get:@"/getHWVersion" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            UInt8 HWVersion = [[MEMELib sharedInstance] getHWVersion];
            [response respondWithString:[NSString stringWithFormat:@"%@", @(HWVersion)]];
        }];
        [self get:@"/getConnectedDeviceType" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            int connectedDeviceType = [[MEMELib sharedInstance] getConnectedDeviceType];
            [response respondWithString:[NSString stringWithFormat:@"%@", @(connectedDeviceType)]];
        }];
        [self get:@"/getConnectedDeviceSubType" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            int connectedDeviceSubType = [[MEMELib sharedInstance] getConnectedDeviceSubType];
            [response respondWithString:[NSString stringWithFormat:@"%@", @(connectedDeviceSubType)]];
        }];

        // Delegate test
        [self get:@"/memeAppAuthorized:" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            [bself requestDelegate:@"memeAppAuthorized:" arguments:@[@"0"]];
        }];
        [self get:@"/memeFirmwareAuthorized:" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            [bself requestDelegate:@"memeFirmwareAuthorized:" arguments:@[@"0"]];
        }];
        [self get:@"/memePeripheralFound:withDeviceAddress:" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            [bself requestDelegate:@"memePeripheralFound:withDeviceAddress:" arguments:@[@"398315C3-0734-400E-9639-6490BAD79086", @"address"]];
        }];
        [self get:@"/memePeripheralConnected:" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            [bself requestDelegate:@"memePeripheralConnected:" arguments:@[@"398315C3-0734-400E-9639-6490BAD79086"]];
        }];
        [self get:@"/memePeripheralDisconnected:" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            [bself requestDelegate:@"memePeripheralDisconnected:" arguments:@[@"398315C3-0734-400E-9639-6490BAD79086"]];
        }];
        [self get:@"/memeRealTimeModeDataReceived:" withBlock:^ (RouteRequest *request, RouteResponse *response) {
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
            [bself requestDelegate:@"memeRealTimeModeDataReceived:" arguments:realTimeData];
        }];
        [self get:@"/memeCommandResponse:" withBlock:^ (RouteRequest *request, RouteResponse *response) {
            [bself requestDelegate:@"memeCommandResponse:" arguments:@[@"0",@"1"]];
        }];
        //
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
    dispatch_group_enter(peripheralManagingGroup);
    __block __unsafe_unretained typeof(self) bself = self;
    dispatch_async(peripheralManagingQueue, ^{

    BOOL alreadyFound = NO;
    for (CBPeripheral *p in bself.peripherals){
        if ([p.identifier isEqual:peripheral.identifier]){
            alreadyFound = YES;
            break;
        }
    }

    if (!alreadyFound)  {
        [bself.peripherals addObject:peripheral];
        NSMutableArray *uuids = @[].mutableCopy;
        for (CBPeripheral *peripheral in bself.peripherals) {
            [uuids addObject:[peripheral.identifier UUIDString]];
        }
    }

    [bself requestDelegate:@"memePeripheralFound:withDeviceAddress:"
                arguments:@[[peripheral.identifier UUIDString], address]];

    dispatch_group_leave(peripheralManagingGroup);

    });
}

- (void)memePeripheralConnected:(CBPeripheral *)peripheral
{
    [self requestDelegate:@"memePeripheralConnected:"
                arguments:@[[peripheral.identifier UUIDString]]];
}

- (void)memePeripheralDisconnected:(CBPeripheral *)peripheral
{
    [self requestDelegate:@"memePeripheralDisconnected:"
                arguments:@[[peripheral.identifier UUIDString]]];
}

- (void)memeRealTimeModeDataReceived:(MEMERealTimeData *)data
{
    NSDictionary *realTimeData = @[
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
    [self requestDelegate:@"memeRealTimeModeDataReceived:"
                arguments:realTimeData];
}

- (void)memeAppAuthorized:(MEMEStatus)status
{
    [self requestDelegate:@"memeAppAuthorized:"
                arguments:@[[NSString stringWithFormat:@"%@", @(status)]]];
}

- (void)memeCommandResponse:(MEMEResponse)response
{
    NSDictionary *r = @[
        [NSString stringWithFormat:@"%@", @(response.eventCode)],
        [NSString stringWithFormat:@"%@", @(response.commandResult)],
    ];
    [self requestDelegate:@"memeCommandResponse:"
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
