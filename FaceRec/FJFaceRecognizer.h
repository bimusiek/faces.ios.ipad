//
//  FaceRecognizer.h
//  opencvtest
//
//  Created by Engin Kurutepe on 21/01/15.
//  Copyright (c) 2015 Fifteen Jugglers Software. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface FJFaceRecognizer : NSObject

- (NSString *)predict:(UIImage*)img confidence:(double *)confidence;
- (void)updateWithFace:(UIImage *)img name:(NSString *)name;
- (NSArray *)labels;

@end
