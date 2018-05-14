//
//  SKRenderingView.m
//  B612Mini
//
//  Created by JohnHong on 2018. 2. 8..
//  Copyright © 2018년 Naver. All rights reserved.
//

#import "SKRenderingView.h"
#import "SKAppEngine.h"
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>


@implementation SKRenderingView
{
    AVCaptureSession *mCaptureSession;
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
        
        [[SKAppEngine sharedAppEngine] initApppEngineWithView:self context:sContext];
        [[SKAppEngine sharedAppEngine] initCaptureSession];
        [[SKAppEngine sharedAppEngine] requestRecording];
    }
    
    return self;
}

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}


#pragma mark - privates



@end
