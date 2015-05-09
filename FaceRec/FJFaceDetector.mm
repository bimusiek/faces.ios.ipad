//
//  CVCameraProvider.mm
//  opencvtest
//
//  Created by Engin Kurutepe on 16/01/15.
//  Copyright (c) 2015 Fifteen Jugglers Software. All rights reserved.
//

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif


#import "FJFaceDetector.h"
#import "UIImage+OpenCV.h"

using namespace cv;

@interface FJFaceDetector () {
    
    CascadeClassifier _faceDetector;

    vector<cv::Rect> _faceRects;
    vector<cv::Mat> _faceImgs;
    vector<cv::Mat> _faceGraysImgs;
    
}

@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, strong) RACSubject *facesDetected;

@end

@implementation FJFaceDetector

- (instancetype)initWithCameraView:(UIImageView *)view scale:(CGFloat)scale {
    self = [super init];
    if (self) {
        self.facesDetected = [[RACSubject alloc] init];
        self.videoCamera = [[CvVideoCamera alloc] initWithParentView:view];
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
        self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
        self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        self.videoCamera.defaultFPS = 30;
        self.videoCamera.grayscaleMode = NO;
        self.videoCamera.delegate = self;
        self.scale = scale;
        
        NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt2"
                                                                ofType:@"xml"];
        
        const CFIndex CASCADE_NAME_LEN = 2048;
        char *CASCADE_NAME = (char *) malloc(CASCADE_NAME_LEN);
        CFStringGetFileSystemRepresentation( (CFStringRef)faceCascadePath, CASCADE_NAME, CASCADE_NAME_LEN);
        
        _faceDetector.load(CASCADE_NAME);
        
        free(CASCADE_NAME);

//        NSString *eyesCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_eye_tree_eyeglasses"
//                                                                    ofType:@"xml"];
//        
//        CFStringGetFileSystemRepresentation( (CFStringRef)eyesCascadePath, CASCADE_NAME, CASCADE_NAME_LEN);
//        
//        eyesDetector.load(CASCADE_NAME);
    }
    
    return self;
}


- (void)startCapture {
    [self.videoCamera start];
}

- (void)stopCapture; {
    [self.videoCamera stop];
}

- (NSArray *)detectedFaces {
    NSMutableArray *facesArray = [NSMutableArray array];
    for( vector<cv::Rect>::const_iterator r = _faceRects.begin(); r != _faceRects.end(); r++ )
    {
        CGRect faceRect = CGRectMake(_scale*r->x/480., _scale*r->y/640., _scale*r->width/480., _scale*r->height/640.);
        [facesArray addObject:[NSValue valueWithCGRect:faceRect]];
    }
    return facesArray;
}

- (UIImage *)faceWithIndex:(NSInteger)idx {
    
    cv::Mat img = self->_faceImgs[idx];
    
    UIImage *ret = [UIImage imageFromCVMat:img];
    
    return ret;
}

- (UIImage *)grayFaceWithIndex:(NSInteger)idx {
    
    cv::Mat img = self->_faceGraysImgs[idx];
    
    UIImage *ret = [UIImage imageFromCVMat:img];
    
    return ret;
}



- (void)processImage:(cv::Mat&)image {
    // Do some OpenCV stuff with the image
    [self detectAndDrawFacesOn:image scale:_scale];
}

- (void)detectAndDrawFacesOn:(Mat&) img scale:(double) scale
{
    int i = 0;
    double t = 0;
    
    const static Scalar colors[] =  { CV_RGB(0,0,255),
        CV_RGB(0,128,255),
        CV_RGB(0,255,255),
        CV_RGB(0,255,0),
        CV_RGB(255,128,0),
        CV_RGB(255,255,0),
        CV_RGB(255,0,0),
        CV_RGB(255,0,255)} ;
    Mat gray, rgbImg, smallImg( cvRound (img.rows/scale), cvRound(img.cols/scale), CV_8UC1 );
    Mat smallColorImgSmall( cvRound (img.rows/scale), cvRound(img.cols/scale), CV_8UC2 );
    
    cvtColor( img, gray, COLOR_BGR2GRAY );
    cvtColor(img, rgbImg, COLOR_BGR2RGB);
    resize( gray, smallImg, smallImg.size(), 0, 0, INTER_LINEAR );
    resize( rgbImg, smallColorImgSmall, smallColorImgSmall.size(), 0, 0, INTER_LINEAR );
    equalizeHist( smallImg, smallImg );
    


    t = (double)cvGetTickCount();
    double scalingFactor = 1.1;
    int minRects = 2;
    cv::Size minSize(30,30);

    self->_faceDetector.detectMultiScale( smallImg, self->_faceRects,
                             scalingFactor, minRects, 0,
                             minSize );

    t = (double)cvGetTickCount() - t;
//    printf( "detection time = %g ms\n", t/((double)cvGetTickFrequency()*1000.) );
    vector<cv::Mat> faceImages;
    vector<cv::Mat> faceGrayImages;
    
    for( vector<cv::Rect>::const_iterator r = _faceRects.begin(); r != _faceRects.end(); r++, i++ )
    {
        cv::Mat smallImgROI;
        cv::Point center;
        Scalar color = colors[i%8];
        vector<cv::Rect> nestedObjects;
        rectangle(img,
                  cvPoint(cvRound(r->x*scale), cvRound(r->y*scale)),
                  cvPoint(cvRound((r->x + r->width-1)*scale), cvRound((r->y + r->height-1)*scale)),
                  color, 3, 8, 0);
        
        //eye detection is pretty low accuracy
//        if( self->eyesDetector.empty() )
//            continue;
//
        cv::Mat crop;
        int x = cvRound(r->x*scale) - 200;
        if(x<0) {
            x = 0;
        }
        
        int y = cvRound(r->y*scale) - 200;
        if(y<0) {
            y = 0;
        }
        int width = x + cvRound(r->width*scale) + 200;
        if(rgbImg.size().width < width) {
            width = rgbImg.size().width;
        }
        int height = y + cvRound(r->height*scale) + 200;
        if(rgbImg.size().height < height) {
            height = rgbImg.size().height;
        }
        
        cv::Rect properRect(x,y,width-x,height-y);

        crop = rgbImg(properRect);
        faceImages.push_back(crop.clone());
        
        smallImgROI = smallImg(*r);
        faceGrayImages.push_back(smallImgROI.clone());
        

        
//        resize(img, crop, Size(128, 128), 0, 0, INTER_LINEAR);
        
//        cv::Point pt1(r->x, r->y); // Display detected faces on main window - live stream from camera
//        cv::Point pt2((r->x + r->height), (r->y + r->width));
//        cv::rectangle(frame, pt1, pt2, Scalar(0, 255, 0), 2, 8, 0);
//
//        
//        
//        self->eyesDetector.detectMultiScale( smallImgROI, nestedObjects,
//                                       1.1, 2, 0,
//                                            cv::Size(5, 5) );
//        for( vector<cv::Rect>::const_iterator nr = nestedObjects.begin(); nr != nestedObjects.end(); nr++ )
//        {
//            center.x = cvRound((r->x + nr->x + nr->width*0.5)*scale);
//            center.y = cvRound((r->y + nr->y + nr->height*0.5)*scale);
//            int radius = cvRound((nr->width + nr->height)*0.25*scale);
//            circle( img, center, radius, color, 3, 8, 0 );
//        }


    }
   
    @synchronized(self) {
        self->_faceImgs = faceImages;
        self->_faceGraysImgs = faceGrayImages;
        
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [((RACSubject*)weakSelf.facesDetected) sendNext:weakSelf];
        });
    }
    
}
@end
