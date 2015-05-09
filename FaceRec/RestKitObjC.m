//
//  RestKitObjC.m
//  iOS-OpenCV-FaceRec
//
//  Created by Michał Hernas on 09/05/15.
//  Copyright (c) 2015 Fifteen Jugglers Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RestKitObjC.h"
#import <RestKit.h>

@implementation RestKitObjC
+ (void)initLogging {
    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
}
@end