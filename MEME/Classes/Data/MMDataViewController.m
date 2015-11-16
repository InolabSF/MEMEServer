//
//  MMDataViewController.m
//  MEMELib_Sample
//
//  Created by JINS MEME on 2015/03/30.
//  Copyright (c) 2015 JINS MEME. All rights reserved.
//

#import "MMDataViewController.h"
#import <MEMELib/MEMELib.h>
#import "MMViewController.h"

@interface MMDataViewController ()

@property (nonatomic, strong) UIView    *indicatorView;

@property (strong, nonatomic) MEMERealTimeData *latestRealTimeData;

@end

@implementation MMDataViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title      = @"RealTime Data";
    
    // Data Commmunication Indicator
    self.indicatorView                  = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 24, 24)];
    self.indicatorView.alpha            = 0.20;
    self.indicatorView.backgroundColor  = [UIColor whiteColor];
    self.indicatorView.layer.cornerRadius = self.indicatorView.frame.size.height * 0.5;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView: self.indicatorView];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @"Disconnect" style:UIBarButtonItemStylePlain target: self action:@selector(disconnectButtonPressed:)];
}

- (void) disconnectButtonPressed:(id) sender
{
    [[MEMELib sharedInstance] disconnectPeripheral];
}

- (void) memeRealTimeModeDataReceived: (MEMERealTimeData *)data
{
    [self blinkIndicator];
    
//    NSLog(@"RealTime Data Received %@", [data description]);
    self.latestRealTimeData = data;
    [self.tableView reloadData];
}

- (void) blinkIndicator
{
    [UIView animateWithDuration: 0.05 animations:  ^{
        self.indicatorView.backgroundColor  = [UIColor redColor]; } completion:^(BOOL finished){
        [UIView animateWithDuration: 0.05 delay:0.25 options: 0 animations: ^{
            self.indicatorView.backgroundColor  = [UIColor whiteColor]; }  completion: nil];
    }];
}

#pragma mark

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 15;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DataCellIdentifier" forIndexPath:indexPath];
    
    NSString *label = @"";
    NSString *value = @"";
  
    MEMERealTimeData *data = self.latestRealTimeData;
    switch (indexPath.row) {
        case 0:
            label = @"Fit Status";
            value = [NSString stringWithFormat: @"%d", data.fitError];
            break;
            
        case 1:
            label = @"Walking";
            value = [NSString stringWithFormat: @"%d", data.isWalking];
            break;
            
        case 2:
            label = @"Power Left";
            value = [NSString stringWithFormat: @"%d", data.powerLeft];
            break;
            
        case 3:
            label = @"Eye Move Up";
            value = [NSString stringWithFormat: @"%d", data.eyeMoveUp];
            break;
            
        case 4:
            label = @"Eye Move Down";
            value = [NSString stringWithFormat: @"%d", data.eyeMoveDown];
            break;
            
        case 5:
            label = @"Eye Move Left";
            value = [NSString stringWithFormat: @"%d", data.eyeMoveLeft];
            break;
            
        case 6:
            label = @"Eye Move Right";
            value = [NSString stringWithFormat: @"%d", data.eyeMoveRight];
            break;
            
        case 7:
            label = @"Blink Streangth";
            value = [NSString stringWithFormat: @"%d", data.blinkStrength];
            break;
            
        case 8:
            label = @"Blink Speed";
            value = [NSString stringWithFormat: @"%d", data.blinkSpeed];
            break;
            
        case 9:
            label = @"Roll";
            value = [NSString stringWithFormat: @"%.2f",data.roll];
            break;
            
        case 10:
            label = @"Pitch";
            value = [NSString stringWithFormat: @"%.2f",data.pitch];
            break;
            
        case 11:
            label = @"Yaw";
            value = [NSString stringWithFormat: @"%.2f",data.yaw];
            break;
            
        case 12:
            label = @"Acc X";
            value = [NSString stringWithFormat: @"%d", data.accX];
            break;
            
        case 13:
            label = @"Acc Y";
            value = [NSString stringWithFormat: @"%d", data.accY];
            break;
            
        case 14:
            label = @"Acc Z";
            value = [NSString stringWithFormat: @"%d", data.accZ];
            break;
            
        default:
            break;
    }
    
    cell.textLabel.text = label;
    cell.detailTextLabel.text = value;
    
    return cell;
}


@end
