//
//  SKCustomAppEngine.h
//  B612Mini
//
//  Created by JohnHong on 2018. 5. 8..
//  Copyright © 2018년 Naver. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>


@interface SKCustomAppEngine : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>


@property (nonatomic, readonly) EAGLContext *context;
@property (nonatomic, readonly) BOOL isStarted;


+ (id)sharedAppEngine;
- (void)initWithContext:(EAGLContext *)aEAGLContext EAGLLayer:(CAEAGLLayer *)aLayer;
- (void)render;
- (void)resumeEngine;
- (void)pauseEngine;


@end
