//
//  MMViewController.h
//  
//
//  Created by JINS MEME on 8/11/14.
//  Copyright (c) 2014 JIN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MEMELib/MEMELib.h>
#import "MMDataViewController.h"

@interface MMViewController : UITableViewController <MEMELibDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) MMDataViewController  *dataViewCtl;

- (IBAction) scanButtonPressed:(id)sender;

@end
