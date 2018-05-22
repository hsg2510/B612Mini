//
//  SKCustomAppEngine.m
//  B612Mini
//
//  Created by JohnHong on 2018. 5. 8..
//  Copyright © 2018년 Naver. All rights reserved.
//

#import "SKCustomAppEngine.h"
#import "CustomRenderingEngine.hpp"
#import "Vector2.h"
#import "Vector4.h"
#include <vector>

using namespace kuru;
using namespace gameplay;
using namespace std;


@implementation SKCustomAppEngine
{
    EAGLContext *mContext;
    CADisplayLink *mDisplayLink;
    BOOL mUpdateFrameBuffer;
    BOOL mIsStarted;
    BOOL mIsStartedCamera;
    
    CAEAGLLayer *mLayer;
    
    CGFloat mViewWidth;
    CGFloat mViewHeight;
    
    GLuint mCameraTextureHandle;
    
    AVCaptureSession *mSession;
    
    CVOpenGLESTextureCacheRef mVideoTextureCache;
    CVOpenGLESTextureRef mCameraTexture;
    
    int mTextureWidth;
    int mTextureHeight;
}


@synthesize context = mContext;
@synthesize isStarted = mIsStarted;


#pragma mark - init, dealloc


+ (id)sharedAppEngine
{
    static SKCustomAppEngine *sSharedAppEngine = nil;
    static dispatch_once_t sOnceToken;
    
    dispatch_once(&sOnceToken, ^{
        sSharedAppEngine = [[self alloc] init];
    });
    
    return sSharedAppEngine;
}


#pragma mark - override


- (void)dealloc
{
    [self tearDownAVCapture];
    
    if ([EAGLContext currentContext] == mContext)
    {
        [EAGLContext setCurrentContext:nil];
    }
}


#pragma mark - public


- (void)initWithContext:(EAGLContext *)aEAGLContext EAGLLayer:(CAEAGLLayer *)aLayer
{
    mContext = aEAGLContext;
    mUpdateFrameBuffer = YES;
    mIsStarted = NO;
    mIsStartedCamera = NO;
    mLayer = aLayer;
    
    NSString* bundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/"];
    FileSystem::setResourcePath([bundlePath fileSystemRepresentation]);
    
    [self setupAVCapture];
}


- (void)render
{
    if (mIsStarted && CustomRenderingEngine::getInstance()->getState() != Game::State::RUNNING)
    {
        return;
    }
    
    NSLog(@"render");
    [EAGLContext setCurrentContext:mContext];
    
    if (mUpdateFrameBuffer)
    {
        mUpdateFrameBuffer = NO;
        
        CustomRenderingEngine::getInstance()->deleteFramebuffer();
        CustomRenderingEngine::getInstance()->createFrameAndColorRenderbuffer();
        
        [mContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:mLayer];
        
        CustomRenderingEngine::getInstance()->attachColorAndDepthBuffer();
    }
    
    if (!mUpdateFrameBuffer && !mIsStarted && mIsStartedCamera)
    {
        mIsStarted = YES;
        
        CustomRenderingEngine::getInstance()->run();
        CustomRenderingEngine::getInstance()->initKuruScene();
        
        [self addCameraTextureNode];
        [self addTestTextureNode];
        [self addTestTextureNode2];
        
        return;
    }
    
    CustomRenderingEngine::getInstance()->bindFramebuffer();
    CustomRenderingEngine::getInstance()->applyViewport();
    CustomRenderingEngine::getInstance()->frame();
    CustomRenderingEngine::getInstance()->bindColorRenderbuffer();
    
    [mContext presentRenderbuffer:GL_RENDERBUFFER];
}


- (void)resumeEngine
{
    CustomRenderingEngine::getInstance()->resume();
}


- (void)pauseEngine
{
    CustomRenderingEngine::getInstance()->pause();
}


#pragma mark - privates

- (void)addTestTextureNode2
{
    Node *sNode = CustomRenderingEngine::getInstance()->addQuadModelAndNode(-1.0, -1.0, 10.0, 10.0);
    [self setDefaultTextureUnlitMaterialWithModel:dynamic_cast<Model*>(sNode->getDrawable()) generateMipmaps:NO];
}


- (void)addTestTextureNode
{
    Node *sNode = CustomRenderingEngine::getInstance()->addQuadModelAndNode(0, 0, 10.0, 10.0);
    [self setDefaultTextureUnlitMaterialWithModel:dynamic_cast<Model*>(sNode->getDrawable()) generateMipmaps:NO];
}

- (void)addCameraTextureNode
{
    Node *sNode = CustomRenderingEngine::getInstance()->addQuadModelAndNode(-10.0, -10.0, 20.0, 20.0);
    [self setTextureUnlitMaterial:dynamic_cast<Model*>(sNode->getDrawable()) generateMipmaps:NO];
}

- (void)setDefaultTextureUnlitMaterialWithModel:(Model *)aModel generateMipmaps:(BOOL)aMipmaps
{
    Material* sMaterial = aModel->setMaterial("textured.vert", "textured.frag");
    sMaterial->setParameterAutoBinding("u_worldViewProjectionMatrix", "WORLD_VIEW_PROJECTION_MATRIX");
    
    // Load the texture from file.
    Texture::Sampler* sSampler = sMaterial->getParameter("u_diffuseTexture")->setValue("color-wheel.png", aMipmaps);
    
    if (aMipmaps)
    {
        sSampler->setFilterMode(Texture::LINEAR_MIPMAP_LINEAR, Texture::LINEAR);
    }
    else
    {
        sSampler->setFilterMode(Texture::LINEAR, Texture::LINEAR);
    }
    
    sSampler->setWrapMode(Texture::CLAMP, Texture::CLAMP);
    sMaterial->getStateBlock()->setCullFace(true);
    sMaterial->getStateBlock()->setDepthTest(false);
    sMaterial->getStateBlock()->setDepthWrite(false);
}


- (void)setTextureUnlitMaterial:(Model *)aModel generateMipmaps:(BOOL)aMipmaps
{
    Material* sMaterial = aModel->setMaterial("Shader2.vsh", "Shader2.fsh");
    sMaterial->setParameterAutoBinding("u_worldViewProjectionMatrix", "WORLD_VIEW_PROJECTION_MATRIX");
    
    // Load the texture from file.
    Texture::Sampler* sSampler = sMaterial->getParameter("SamplerRGB")->setValue(mCameraTextureHandle, aMipmaps, mTextureWidth, mTextureHeight);
    
    if (aMipmaps)
    {
        sSampler->setFilterMode(Texture::LINEAR_MIPMAP_LINEAR, Texture::LINEAR);
    }
    else
    {
        sSampler->setFilterMode(Texture::LINEAR, Texture::LINEAR);
    }
    
    sSampler->setWrapMode(Texture::CLAMP, Texture::CLAMP);
    sMaterial->getStateBlock()->setCullFace(true);
    sMaterial->getStateBlock()->setDepthTest(false);
    sMaterial->getStateBlock()->setDepthWrite(false);
}


- (void)setupAVCapture
{
    //-- Create CVOpenGLESTextureCacheRef for optimal CVImageBufferRef to GLES texture conversion.
#if COREVIDEO_USE_EAGLCONTEXT_CLASS_IN_API
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, mContext, NULL, &mVideoTextureCache);
#else
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)_context, NULL, &mVideoTextureCache);
#endif
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        return;
    }

    //-- Setup Capture Session.
    mSession = [[AVCaptureSession alloc] init];
    [mSession beginConfiguration];

    //-- Set preset session size.
    [mSession setSessionPreset:AVCaptureSessionPreset1280x720];

    //-- Creata a video device and input from that Device.  Add the input to the capture session.
    AVCaptureDevice * videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if(videoDevice == nil)
        assert(0);

    //-- Add the device to the session.
    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if(error)
        assert(0);

    [mSession addInput:input];

    //-- Create the output for the capture session.
    AVCaptureVideoDataOutput * dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [dataOutput setAlwaysDiscardsLateVideoFrames:YES]; // Probably want to set this to NO when recording

    //-- Set to YUV420.
    [dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                             forKey:(id)kCVPixelBufferPixelFormatTypeKey]]; // Necessary for manual preview

    // Set dispatch to be on the main thread so OpenGL can do things with the data
    [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];

    [mSession addOutput:dataOutput];
    [mSession commitConfiguration];

    [mSession startRunning];
}


- (void)cleanUpTextures
{
    if (mCameraTexture)
    {
        CFRelease(mCameraTexture);
        mCameraTexture = NULL;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(mVideoTextureCache, 0);
}


#pragma mark - delegate


- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    if (mIsStarted && CustomRenderingEngine::getInstance()->getState() != Game::State::RUNNING)
    {
        return;
    }
    
    CVReturn err;
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    if (!mVideoTextureCache)
    {
        NSLog(@"No video texture cache");
        return;
    }
    
    if ( width != mTextureWidth || height != mTextureHeight)
    {
        mTextureWidth = (int)width;
        mTextureHeight = (int)height;
        mIsStartedCamera = YES;
    }
    
    [self cleanUpTextures];
    
    // CVOpenGLESTextureCacheCreateTextureFromImage will create GLES texture
    // optimally from CVImageBufferRef.
    
    glActiveTexture(GL_TEXTURE0);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       mVideoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RGBA,
                                                       mTextureWidth,
                                                       mTextureHeight,
                                                       GL_BGRA,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &mCameraTexture);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    mCameraTextureHandle = CVOpenGLESTextureGetName(mCameraTexture);
}


- (void)tearDownAVCapture
{
    [self cleanUpTextures];
    
    CFRelease(mVideoTextureCache);
}


@end
