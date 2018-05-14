//
//  SKAppEngine.m
//  B612Mini
//
//  Created by JohnHong on 2018. 2. 12..
//  Copyright © 2018년 Naver. All rights reserved.
//

#import "SKAppEngine.h"
#import "RenderingEngine.hpp"
#import "SKQueueDispatcher.h"
#import "SKRenderingCacheStorage.h"

using namespace kuru;
using namespace gameplay;


static int32_t const kDefaultFrameRate = 30;

const char* kCaptureVideoSessionQueueIdentifier = "captureVideoSessionQueueIdentifier";


@implementation SKAppEngine
{
    EAGLContext *mContext;
    AVCaptureSession *mCaptureSession;
    UIView *mRenderingView;
    CGFloat mViewWidth;
    CGFloat mViewHeight;
    
    dispatch_semaphore_t mVideoFrameRenderingSemaphore;
}


@synthesize context = mContext;


#pragma mark - init


+ (id)sharedAppEngine
{
    static SKAppEngine *sSharedAppEngine = nil;
    static dispatch_once_t sOnceToken;
    
    dispatch_once(&sOnceToken, ^{
        sSharedAppEngine = [[self alloc] init];
    });
    
    return sSharedAppEngine;
}


#pragma mark - override


- (void)dealloc
{
    if ([EAGLContext currentContext] == mContext)
    {
        [EAGLContext setCurrentContext:nil];
    }
}


#pragma mark - public


- (void)initApppEngineWithView:(UIView *)aView context:(EAGLContext *)aEAGLContext
{
    mRenderingView = aView;
    mContext = aEAGLContext;
    
    CGSize sViewSize = [mRenderingView bounds].size;
    mViewWidth = sViewSize.width;
    mViewHeight = sViewSize.height;
    
    NSString* bundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/"];
    FileSystem::setResourcePath([bundlePath fileSystemRepresentation]);
    
//    CAEAGLLayer *sEaglLayer = (CAEAGLLayer *)[mRenderingView layer];
//    NSDictionary *sDrawablePropertiesDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
//    CGFloat sScreenScale = [[UIScreen mainScreen] scale];
//    [sEaglLayer setOpaque:YES];
//    [sEaglLayer setDrawableProperties:sDrawablePropertiesDict];
//    [sEaglLayer setContentsScale:sScreenScale];
//    [mRenderingView setContentScaleFactor:sScreenScale];
    
    RenderingEngine *sEngine = RenderingEngine::getInstance();
    
    sEngine->initPrevAllocFramebuffer();
    
    [mContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)[mRenderingView layer]];
    
    sEngine->initializeForCustom();
    sEngine->run();
    
    glActiveTexture(GL_TEXTURE0);
}


- (void)initCaptureSession
{
    mCaptureSession = [[AVCaptureSession alloc] init];
    [mCaptureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    
    AVCaptureDevice *sDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [sDevice setActiveVideoMinFrameDuration:CMTimeMake(1, kDefaultFrameRate)];
    [sDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, kDefaultFrameRate)];
    
    NSError *sError = nil;
    AVCaptureDeviceInput *sInput = [AVCaptureDeviceInput deviceInputWithDevice:sDevice error:&sError];
    
    if (!sInput)
    {
        NSLog(@"create device input error!!");
        
        return;
    }
    
    [mCaptureSession addInput:sInput];
    
    AVCaptureVideoDataOutput *sOutput = [[AVCaptureVideoDataOutput alloc] init];
    [mCaptureSession addOutput:sOutput];
    [sOutput setVideoSettings:@{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) }];
    
    dispatch_queue_t sQueue = dispatch_queue_create(kCaptureVideoSessionQueueIdentifier, NULL);
    [sOutput setSampleBufferDelegate:self queue:sQueue];
}


- (void)requestRecording
{
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL aGranted) {
        if (aGranted)
        {
            //Granted access to mediaType
            [mCaptureSession startRunning];
        }
        else
        {
            NSLog(@"not granted for camera");
        }
    }];
}


- (void)pauseEngine
{
    RenderingEngine *sEngine = RenderingEngine::getInstance();
    
    if(sEngine->isRunning())
    {
        sEngine->pause();
    }
}


- (void)resumeEngine
{
    RenderingEngine *sEngine = RenderingEngine::getInstance();
    
    if (sEngine->isPause())
    {
        sEngine->resume();
    }
}


- (SKRenderingState)renderingState
{
    RenderingEngine *sEngine = RenderingEngine::getInstance();
    RenderingEngine::State sState = sEngine->getState();
    
    return (SKRenderingState)sState;
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate


- (void)captureOutput:(AVCaptureOutput *)aCaptureOutput didOutputSampleBuffer:(CMSampleBufferRef)aSampleBuffer fromConnection:(AVCaptureConnection *)aConnection
{
     [EAGLContext setCurrentContext:mContext];
    NSLog(@"aaaa");
    
    CMTime sCurrentTime = CMSampleBufferGetPresentationTimeStamp(aSampleBuffer);
    CVPixelBufferRef sCVPixelBufferRef = CMSampleBufferGetImageBuffer(aSampleBuffer);
    
    CFRetain(aSampleBuffer);
//    [[SKQueueDispatcher sharedDispatcher] runAsynchronouslyOnGLRenderingQueue:^{
        RenderingEngine *sEngine = RenderingEngine::getInstance();
        sEngine->processPrevRendering(mViewWidth, mViewHeight);

        RenderingEngine::getInstance()->frame();

        [self makeTextureFrom:sCVPixelBufferRef withCurrentTime:sCurrentTime];
//        [mContext presentRenderbuffer:GL_RENDERBUFFER];
        CFRelease(aSampleBuffer);
//    }];
}

#pragma mark - privates


- (void)startGame
{
    
}


- (void)makeTextureFrom:(CVPixelBufferRef)aPixelBufferRef withCurrentTime:(CMTime)aCurrentTime
{
    CVReturn sErr;
    CVOpenGLESTextureRef sRGBTextureRef = NULL;
    
    CVPixelBufferLockBaseAddress(aPixelBufferRef, 0);
    
    int sPixelBufferWidth = (int)CVPixelBufferGetWidth(aPixelBufferRef);
    int sPixelBufferHeight = (int)CVPixelBufferGetHeight(aPixelBufferRef);
    
    sErr = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       [[SKRenderingCacheStorage sharedRenderingCacheStorage] coreVideoTextureCacheRef],
                                                       aPixelBufferRef, NULL, GL_TEXTURE_2D, GL_RGBA,
                                                       sPixelBufferWidth,
                                                       sPixelBufferHeight, GL_BGRA, GL_UNSIGNED_BYTE, 0, &sRGBTextureRef);
    
    CVPixelBufferUnlockBaseAddress(aPixelBufferRef, 0);
    
    if (sErr != kCVReturnSuccess || !sRGBTextureRef)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", sErr);
        NSLog(@"--------------------- error --------------------------");

        return;
    }
    
    GLuint sCoreVideoTexture;
    sCoreVideoTexture = CVOpenGLESTextureGetName(sRGBTextureRef);
    glBindTexture(CVOpenGLESTextureGetTarget(sRGBTextureRef), sCoreVideoTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    [[SKRenderingCacheStorage sharedRenderingCacheStorage] setCoreVideoTexture:sCoreVideoTexture];
}

@end
