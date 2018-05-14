//
//  SKCustomRenderingView.m
//  B612Mini
//
//  Created by JohnHong on 2018. 5. 8..
//  Copyright © 2018년 Naver. All rights reserved.
//

#import "SKCustomRenderingView.h"
#import "SKCustomAppEngine.h"

#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>
#import <AVFoundation/AVFoundation.h>


@implementation SKCustomRenderingView
{
    AVCaptureSession *mCaptureSession;
    CADisplayLink *mDisplayLink;
    BOOL mUpdating;
}


#pragma mark - override


- (instancetype)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    
    if (self)
    {
        EAGLContext *sContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!sContext || ![EAGLContext setCurrentContext:sContext])
        {
            NSLog(@"Failed to make context current.");
            
            return nil;
        }
        
        CAEAGLLayer *sLayer = (CAEAGLLayer *)[self layer];
        NSDictionary *sDrawablePropertiesDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        CGFloat sScreenScale = [[UIScreen mainScreen] scale];
        
        [sLayer setOpaque:YES];
        [sLayer setDrawableProperties:sDrawablePropertiesDict];
        [sLayer setContentsScale:sScreenScale];
        [self setContentScaleFactor:sScreenScale];
        
        mUpdating = NO;
        
        [[SKCustomAppEngine sharedAppEngine] initWithContext:sContext EAGLLayer:sLayer];
        
//        mDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView:)];
//        [mDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    
    return self;
}

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}


#pragma mark - public


- (void)startUpdating
{
    if (!mUpdating)
    {
        mDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView:)];
        [mDisplayLink setPreferredFramesPerSecond:30];
        [mDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        if ([[SKCustomAppEngine sharedAppEngine] isStarted])
        {
            [[SKCustomAppEngine sharedAppEngine] resumeEngine];
        }
    }
}


- (void)stopUpdating
{
    if (mUpdating)
    {
        if ([[SKCustomAppEngine sharedAppEngine] isStarted])
        {
            [[SKCustomAppEngine sharedAppEngine] pauseEngine];
        }
        
        [mDisplayLink invalidate];
        mDisplayLink = nil;
        mUpdating = NO;
    }
}


#pragma mark - call back


- (void)drawView:(CADisplayLink *)CADisplayLink
{
    [[SKCustomAppEngine sharedAppEngine] render];
}


@end
