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


enum
{
    UNIFORM_Y,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};


struct Vertex {
    Vector4 Position;
    Vector2 TexturePosition;
};


@implementation SKCustomAppEngine
{
    EAGLContext *mContext;
    CADisplayLink *mDisplayLink;
    BOOL mUpdateFrameBuffer;
    BOOL mIsStarted;
    
    CAEAGLLayer *mLayer;
    
    CGFloat mViewWidth;
    CGFloat mViewHeight;
    
    
    GLuint mColorRenderbuffer;
    GLuint mDepthRenderBuffer;
    GLuint mFrameBuffer;
    GLuint mPositionBuffer;
    GLuint mIndexBuffer;
    
//    AVCaptureSession *mSession;
    
    CVOpenGLESTextureCacheRef mVideoTextureCache;
    CVOpenGLESTextureRef mLumaTexture;
    CVOpenGLESTextureRef mChromaTexture;
    
    int mTextureWidth;
    int mTextureHeight;
}


@synthesize context = mContext;
@synthesize isStarted = mIsStarted;


#pragma mark - init


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
    mLayer = aLayer;
    
    NSString* bundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/"];
    FileSystem::setResourcePath([bundlePath fileSystemRepresentation]);
}


- (void)render
{
    [EAGLContext setCurrentContext:mContext];
    
    if (mUpdateFrameBuffer)
    {
        mUpdateFrameBuffer = NO;
        
        if (mContext)
        {
            CustomRenderingEngine::getInstance()->deleteFramebuffer();
            CustomRenderingEngine::getInstance()->createFrameAndColorRenderbuffer();
            
            [mContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:mLayer];
            
            CustomRenderingEngine::getInstance()->attachColorAndDepthBuffer();
        }
        
        if (!mIsStarted)
        {
            mIsStarted = YES;
            
            CustomRenderingEngine::getInstance()->run();
            CustomRenderingEngine::getInstance()->initKuruScene();
            
            return;
        }
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


//- (void)setupGL
//{
//    [self loadShaders];
//
//    glUseProgram(CustomRenderingEngine::getInstance()->mProgram);
//
//    glUniform1i(uniforms[UNIFORM_Y], 0);
//}


//- (void)setupAVCapture
//{
//    //-- Create CVOpenGLESTextureCacheRef for optimal CVImageBufferRef to GLES texture conversion.
//#if COREVIDEO_USE_EAGLCONTEXT_CLASS_IN_API
//    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, mContext, NULL, &mVideoTextureCache);
//#else
//    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)_context, NULL, &mVideoTextureCache);
//#endif
//    if (err)
//    {
//        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
//        return;
//    }
//
//    //-- Setup Capture Session.
//    mSession = [[AVCaptureSession alloc] init];
//    [mSession beginConfiguration];
//
//    //-- Set preset session size.
//    [mSession setSessionPreset:AVCaptureSessionPreset1280x720];
//
//    //-- Creata a video device and input from that Device.  Add the input to the capture session.
//    AVCaptureDevice * videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//    if(videoDevice == nil)
//        assert(0);
//
//    //-- Add the device to the session.
//    NSError *error;
//    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
//    if(error)
//        assert(0);
//
//    [mSession addInput:input];
//
//    //-- Create the output for the capture session.
//    AVCaptureVideoDataOutput * dataOutput = [[AVCaptureVideoDataOutput alloc] init];
//    [dataOutput setAlwaysDiscardsLateVideoFrames:YES]; // Probably want to set this to NO when recording
//
//    //-- Set to YUV420.
//    [dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
//                                                             forKey:(id)kCVPixelBufferPixelFormatTypeKey]]; // Necessary for manual preview
//
//    // Set dispatch to be on the main thread so OpenGL can do things with the data
//    [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
//
//    [mSession addOutput:dataOutput];
//    [mSession commitConfiguration];
//
//    [mSession startRunning];
//}

//- (void)setupBuffers
//{
//    vector<Vertex> sRectVertices(4);
//    vector<Vertex>::iterator sVertex = sRectVertices.begin();
//
//    sVertex->Position = Vector4(-1.0, -1.0, 1, 1);
//    sVertex->TexturePosition = Vector2(1, 1);
//    sVertex++;
//    sVertex->Position = Vector4(-1.0, 1.0, 1, 1);
//    sVertex->TexturePosition = Vector2(0, 1);
//    sVertex++;
//    sVertex->Position = Vector4(1.0, 1.0, 1, 1);
//    sVertex->TexturePosition = Vector2(0, 0);
//    sVertex++;
//    sVertex->Position = Vector4(1.0, -1.0, 1, 1);
//    sVertex->TexturePosition = Vector2(1, 0);
//
//    glGenBuffers(1, &mPositionBuffer);
//    glBindBuffer(GL_ARRAY_BUFFER, mPositionBuffer);
//    glBufferData(GL_ARRAY_BUFFER, sRectVertices.size() * sizeof(sRectVertices[0]), &sRectVertices[0], GL_STATIC_DRAW);
//
//    vector<GLubyte> sIndices(4);
//    vector<GLubyte>::iterator sIndex = sIndices.begin();
//
//    *sIndex = 3;
//    sIndex++;
//    *sIndex = 2;
//    sIndex++;
//    *sIndex = 1;
//    sIndex++;
//    *sIndex = 0;
//
//    glGenBuffers(1, &mIndexBuffer);
//    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mIndexBuffer);
//    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sIndices.size() * sizeof(sIndices[0]), &sIndices[0], GL_STATIC_DRAW);
//
//    glEnableVertexAttribArray(ATTRIB_VERTEX);
//    glVertexAttribPointer(ATTRIB_VERTEX, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
//
//    const void *sTexCoordOffset = (GLvoid *)sizeof(Vector4);
//
//    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
//    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), sTexCoordOffset);
//}


//- (void)makeTextureFrom:(CVPixelBufferRef)aPixelBufferRef withCurrentTime:(CMTime)aCurrentTime
//{
//    CVReturn sErr;
//    CVOpenGLESTextureRef sRGBTextureRef = NULL;
//
//    CVPixelBufferLockBaseAddress(aPixelBufferRef, 0);
//
//    int sPixelBufferWidth = (int)CVPixelBufferGetWidth(aPixelBufferRef);
//    int sPixelBufferHeight = (int)CVPixelBufferGetHeight(aPixelBufferRef);
//
//    sErr = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
//                                                        [[SKRenderingCacheStorage sharedRenderingCacheStorage] coreVideoTextureCacheRef],
//                                                        aPixelBufferRef, NULL, GL_TEXTURE_2D, GL_RGBA,
//                                                        sPixelBufferWidth,
//                                                        sPixelBufferHeight, GL_BGRA, GL_UNSIGNED_BYTE, 0, &sRGBTextureRef);
//
//    CVPixelBufferUnlockBaseAddress(aPixelBufferRef, 0);
//
//    if (sErr != kCVReturnSuccess || !sRGBTextureRef)
//    {
//        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", sErr);
//        NSLog(@"--------------------- error --------------------------");
//
//        return;
//    }
//
//    GLuint sCoreVideoTexture;
//    sCoreVideoTexture = CVOpenGLESTextureGetName(sRGBTextureRef);
//    glBindTexture(CVOpenGLESTextureGetTarget(sRGBTextureRef), sCoreVideoTexture);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//
//    [[SKRenderingCacheStorage sharedRenderingCacheStorage] setCoreVideoTexture:sCoreVideoTexture];
//}


//- (void)cleanUpTextures
//{
//    if (mLumaTexture)
//    {
//        CFRelease(mLumaTexture);
//        mLumaTexture = NULL;
//    }
//    
//    if (mChromaTexture)
//    {
//        CFRelease(mChromaTexture);
//        mChromaTexture = NULL;
//    }
//    
//    // Periodic texture cache flush every frame
//    CVOpenGLESTextureCacheFlush(mVideoTextureCache, 0);
//}


#pragma mark - delegate


//- (void)captureOutput:(AVCaptureOutput *)captureOutput
//didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
//       fromConnection:(AVCaptureConnection *)connection
//{
//    CVReturn err;
//    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//    size_t width = CVPixelBufferGetWidth(pixelBuffer);
//    size_t height = CVPixelBufferGetHeight(pixelBuffer);
//    
//    if (!mVideoTextureCache)
//    {
//        NSLog(@"No video texture cache");
//        return;
//    }
//    
//    if ( width != mTextureWidth || height != mTextureHeight)
//    {
//        mTextureWidth = (int)width;
//        mTextureHeight = (int)height;
//        
//        [self setupBuffers];
//        mIsStartedCamera = YES;
//    }
//    
//    NSLog(@"capture frame");
//    
//    [self cleanUpTextures];
//    
//    // CVOpenGLESTextureCacheCreateTextureFromImage will create GLES texture
//    // optimally from CVImageBufferRef.
//    
//    
//    // Y-plane
//    glActiveTexture(GL_TEXTURE0);
//    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
//                                                       mVideoTextureCache,
//                                                       pixelBuffer,
//                                                       NULL,
//                                                       GL_TEXTURE_2D,
//                                                       GL_RGBA,
//                                                       mTextureWidth,
//                                                       mTextureHeight,
//                                                       GL_BGRA,
//                                                       GL_UNSIGNED_BYTE,
//                                                       0,
//                                                       &mLumaTexture);
//    if (err)
//    {
//        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
//    }
//    
//    glBindTexture(CVOpenGLESTextureGetTarget(mLumaTexture), CVOpenGLESTextureGetName(mLumaTexture));
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//}


#pragma mark - OpenGL ES 2 shader compilation

//- (BOOL)loadShaders
//{
//    GLuint vertShader, fragShader;
//    NSString *vertShaderPathname, *fragShaderPathname;
//    
//    // Create shader program.
//    CustomRenderingEngine::getInstance()->mProgram = glCreateProgram();
//    
//    // Create and compile vertex shader.
//    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
//    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
//        NSLog(@"Failed to compile vertex shader");
//        return NO;
//    }
//    
//    // Create and compile fragment shader.
//    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
//    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
//        NSLog(@"Failed to compile fragment shader");
//        return NO;
//    }
//    
//    // Attach vertex shader to program.
//    glAttachShader(CustomRenderingEngine::getInstance()->mProgram, vertShader);
//    
//    // Attach fragment shader to program.
//    glAttachShader(CustomRenderingEngine::getInstance()->mProgram, fragShader);
//    
//    // Bind attribute locations.
//    // This needs to be done prior to linking.
//    glBindAttribLocation(CustomRenderingEngine::getInstance()->mProgram, ATTRIB_VERTEX, "position");
//    glBindAttribLocation(CustomRenderingEngine::getInstance()->mProgram, ATTRIB_TEXCOORD, "texCoord");
//    
//    // Link program.
//    if (![self linkProgram:CustomRenderingEngine::getInstance()->mProgram]) {
//        NSLog(@"Failed to link program: %d", CustomRenderingEngine::getInstance()->mProgram);
//        
//        if (vertShader) {
//            glDeleteShader(vertShader);
//            vertShader = 0;
//        }
//        if (fragShader) {
//            glDeleteShader(fragShader);
//            fragShader = 0;
//        }
//        if (CustomRenderingEngine::getInstance()->mProgram) {
//            glDeleteProgram(CustomRenderingEngine::getInstance()->mProgram);
//            CustomRenderingEngine::getInstance()->mProgram = 0;
//        }
//        
//        return NO;
//    }
//    
//    // Get uniform locations.
////    uniforms[UNIFORM_Y] = glGetUniformLocation(CustomRenderingEngine::getInstance()->mProgram, "SamplerY");
////    uniforms[UNIFORM_UV] = glGetUniformLocation(CustomRenderingEngine::getInstance()->mProgram, "SamplerUV");
//    uniforms[UNIFORM_Y] = glGetUniformLocation(CustomRenderingEngine::getInstance()->mProgram, "SamplerRGB");
//    
//    // Release vertex and fragment shaders.
//    if (vertShader) {
//        glDetachShader(CustomRenderingEngine::getInstance()->mProgram, vertShader);
//        glDeleteShader(vertShader);
//    }
//    if (fragShader) {
//        glDetachShader(CustomRenderingEngine::getInstance()->mProgram, fragShader);
//        glDeleteShader(fragShader);
//    }
//    
//    return YES;
//}
//
//
//- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
//{
//    GLint status;
//    const GLchar *source;
//    
//    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
//    if (!source) {
//        NSLog(@"Failed to load vertex shader");
//        return NO;
//    }
//    
//    *shader = glCreateShader(type);
//    glShaderSource(*shader, 1, &source, NULL);
//    glCompileShader(*shader);
//    
//#if defined(DEBUG)
//    GLint logLength;
//    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
//    if (logLength > 0) {
//        GLchar *log = (GLchar *)malloc(logLength);
//        glGetShaderInfoLog(*shader, logLength, &logLength, log);
//        NSLog(@"Shader compile log:\n%s", log);
//        free(log);
//    }
//#endif
//    
//    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
//    if (status == 0) {
//        glDeleteShader(*shader);
//        return NO;
//    }
//    
//    return YES;
//}
//
//- (BOOL)linkProgram:(GLuint)prog
//{
//    GLint status;
//    glLinkProgram(prog);
//    
//#if defined(DEBUG)
//    GLint logLength;
//    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
//    if (logLength > 0) {
//        GLchar *log = (GLchar *)malloc(logLength);
//        glGetProgramInfoLog(prog, logLength, &logLength, log);
//        NSLog(@"Program link log:\n%s", log);
//        free(log);
//    }
//#endif
//    
//    glGetProgramiv(prog, GL_LINK_STATUS, &status);
//    if (status == 0) {
//        return NO;
//    }
//    
//    return YES;
//}


#pragma mark - private


//- (unsigned char *)bytesFromData:(NSData *)NSMutableData
//{
//    NSData * data;
//    unsigned char * sData = (unsigned char *)[data bytes];
//
//    return sData;
//}
//
//- (NSData *)imageToBuffer:(CMSampleBufferRef)aSource
//{
//    CVImageBufferRef sImageBuffer = CMSampleBufferGetImageBuffer(aSource);
//    CVPixelBufferLockBaseAddress(sImageBuffer,0);
//
//    size_t sBytesPerRow = CVPixelBufferGetBytesPerRow(sImageBuffer);
////    size_t width = CVPixelBufferGetWidth(sImageBuffer);
//    size_t height = CVPixelBufferGetHeight(sImageBuffer);
//    void *src_buff = CVPixelBufferGetBaseAddress(sImageBuffer);
//
//    NSData *data = [NSData dataWithBytes:src_buff length:sBytesPerRow * height];
//
//    CVPixelBufferUnlockBaseAddress(sImageBuffer, 0);
//
//    return data;
//}
//

@end
