//
//  Interpreter.m
//  CoinCounter
//
//  Created by PointerFLY on 17/07/2018.
//  Copyright © 2018 PointerFLY. All rights reserved.
//

#include "opencv2/opencv.hpp"
#import "Interpreter.h"

#include "opencv2/imgcodecs/ios.h"
#include <vector>
#include "tensorflow/contrib/lite/kernels/register.h"
#include "tensorflow/contrib/lite/model.h"
#include "tensorflow/contrib/lite/string_util.h"
#include "tensorflow/contrib/lite/tools/mutable_op_resolver.h"

using namespace cv;
using namespace std;

@implementation InterpreterResult
@end

@implementation Interpreter {
    std::unique_ptr<tflite::FlatBufferModel> _model;
    std::unique_ptr<tflite::Interpreter> _interpreter;
    std::vector<std::string> _labels;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupTFModel];
    }
    return self;
}

- (InterpreterResult *)runOnFrame:(CVPixelBufferRef)pixelBuffer {
    Mat mRgba = [self readMatFromPixelBuffer:pixelBuffer];
    Mat mGray;
    cvtColor(mRgba, mGray, CV_RGBA2GRAY);
    
    GaussianBlur(mGray, mGray, cv::Size(5, 5), 2, 2);
    vector<Vec3f> circles;
    HoughCircles(mGray, circles, CV_HOUGH_GRADIENT, 1, mGray.rows / 20, 100, 60, 20, 100);
    
    for( size_t i = 0; i < circles.size(); i++ ) {
        cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
        int radius = cvRound(circles[i][2]);
        circle(mRgba, center, radius, Scalar(255, 0, 0, 255), 2);
    }
    
    NSDictionary* coinInfo = @{@"10 Cent" : [NSNumber numberWithInt:1],
                               @"20 Cent" : [NSNumber numberWithInt:2],
                               @"50 Cent" : [NSNumber numberWithInt:1],
                               @"1 Cent" : [NSNumber numberWithInt:2],
                               @"2 Euro" : [NSNumber numberWithInt:1],
                               @"5 Cent" : [NSNumber numberWithInt:2],
                               @"1 Cent" : [NSNumber numberWithInt:2]};
    InterpreterResult* result = [[InterpreterResult alloc] init];
    result.image = MatToUIImage(mRgba);
    result.coinInfo = coinInfo;
    
    return result;
}

- (void)runTFModel:(Mat)mGray {
    
}

- (void)setupTFModel {
    // Load Model
    
    NSString* modelPath = [[NSBundle mainBundle] pathForResource:@"model" ofType:@"tflite"];
    _model = tflite::FlatBufferModel::BuildFromFile([modelPath UTF8String]);
    _model->error_reporter();
    
    tflite::ops::builtin::BuiltinOpResolver resolver;
    tflite::InterpreterBuilder(*_model, resolver)(&_interpreter);
    assert(_interpreter->AllocateTensors() == kTfLiteOk);
    
    // Load labels
    
    NSString* labelsPath = [[NSBundle mainBundle] pathForResource:@"labels" ofType:@"txt"];
    ifstream ifs([labelsPath UTF8String]);
    std::string line;
    while (ifs) {
        std::getline(ifs, line);
        _labels.push_back(line);
    }
}

- (Mat)readMatFromPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    void* address =  CVPixelBufferGetBaseAddress(pixelBuffer);
    int width = static_cast<int>(CVPixelBufferGetWidth(pixelBuffer));
    int height = static_cast<int>(CVPixelBufferGetHeight(pixelBuffer));
    
    Mat mRgba = Mat(height, width, CV_8UC4, address, 0);
    rotate(mRgba, mRgba, ROTATE_90_CLOCKWISE);
    cvtColor(mRgba, mRgba, CV_BGRA2RGBA);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return mRgba;
}

@end
