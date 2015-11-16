//
//  MMDataParser.m
//  MEME_Test
//
//  Created by Nao Tokui on 10/10/14.
//  Copyright (c) 2014 Nao Tokui. All rights reserved.
//

#import "MMDataParser.h"

@implementation MMDataParser



- (void) memeDataUpdated:(NSData *) value
{
    if (value.length == 20){
        u_char *bytes = (u_char *)value.bytes;
        
        char type = bytes[1];
        switch (type) {
            case 0:
                //                NSLog(@"value %@", [value description]);
                
                [self parseEOG:bytes];
                break;
                
            case 1:
                [self parseAccerelation:bytes];
                break;
                
            default:
                break;
        }
        
        //        NSLog(@"type %d", type);
    }
}

- (void) parseEOG: (u_char *)bytes
{
    // Main threadで呼ばれる    
    int _eog[3][3];
    
    for (int j=0; j < 3; j++){          // 3回の試行
        for (int i=0; i < 3; i++){      // 3種類のデータ
            
            u_char evenValue  =  bytes[ 2 + (i * 2) + (6 * j)];
            u_char oddValue   =  bytes[ 2 + (i * 2) + 1 + (6 * j)];
            
            short sum = (evenValue >> 4 | oddValue << 4);
            
            if (sum >> 11){ // 最初の1ビットをチェック!
                sum = ~sum & 0xFFF;  // 反転. 最初の4ビットは無視
                sum = -sum -1;
            }
            //   NSLog(@"%x %x %x %d", evenValue >> 4, oddValue << 4, sum, sum);
            
            _eog[j][i] = sum;
        }
    }
    
    // 平均を出す
    for (int i=0; i < 3; i++){
        float sum = 0;
        for (int j =0; j < 3; j++){
            sum += _eog[j][i];
        }
        _eog[i] = sum / 3.0;
    }
    NSLog(@"EOG %d %d %d", _eog[0], _eog[1], _eog[2]);
}


- (void) parseAccerelation: (u_char *)bytes
{
    for (int j=0; j < 2; j++){
        for (int i=0; i < 3; i++){
            
            u_char evenValue  =  bytes[ 2 + i * 2 + 6 * j];
            u_char oddValue   =  bytes[ 2 + i * 2 + 1 + 6 * j];
            
            short sum = (evenValue  | oddValue << 8);
            
            if (sum >> 15){ // 最初の1ビットをチェック!
                sum = ~sum;  // 反転. 最初の4ビットは無視
                sum = -sum -1;
            }
            //   NSLog(@"%x %x %x %d", evenValue, oddValue << 8, sum, sum);
            
            if (j == 0) ax[i] = sum;
            else aax[i] = sum;
        }
    }
    
    NSLog(@"aac %d %d %d  --  angular aac %d %d %d", ax[0], ax[1], ax[2], aax[0], aax[1], aax[2]);
}


@end
