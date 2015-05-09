//
//  CVCameraProvider.h
//  opencvtest
//
//  Created by Engin Kurutepe on 16/01/15.
//  Copyright (c) 2015 Fifteen Jugglers Software. All rights reserved.
//

#import <opencv2/highgui/cap_ios.h>
#import <Foundation/Foundation.h>
#import <ReactiveCocoa.h>

@interface FJFaceDetector : NSObject <CvVideoCameraDelegate>

@property (nonatomic, strong) CvVideoCamera* videoCamera;
@property (nonatomic, strong, readonly) RACSignal *facesDetected;

- (instancetype)initWithCameraView:(UIImageView *)view scale:(CGFloat)scale;

- (void)startCapture;
- (void)stopCapture;

- (NSArray *)detectedFaces;
- (UIImage *)faceWithIndex:(NSInteger)idx;
- (UIImage *)grayFaceWithIndex:(NSInteger)idx;

@end
