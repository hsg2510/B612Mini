//
//  ViewController.m
//  B612Mini
//
//  Created by JohnHong on 2018. 2. 8..
//  Copyright © 2018년 Naver. All rights reserved.
//

#import "ViewController.h"
#import "SKRenderingView.h"
#import "Vector2.h"
#import "Vector4.h"

#include <vector>
#include <iostream>

using namespace std;
using namespace gameplay;


// Uniform index.
//enum
//{
//    UNIFORM_Y,
//    UNIFORM_UV,
//    NUM_UNIFORMS
//};
//GLint uniforms[NUM_UNIFORMS];


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


@implementation ViewController
{
    EAGLContext *mContext;
    NSString *mSessionPreset;
    GLuint mProgram;
    AVCaptureSession *mSession;
    CVOpenGLESTextureCacheRef mVideoTextureCache;
    CVOpenGLESTextureRef mLumaTexture;
    CVOpenGLESTextureRef mChromaTexture;
    GLuint mPositionBuffer;
    GLuint mIndexBuffer;
    
    int mTextureWidth;
    int mTextureHeight;
    
    BOOL mIsStartedCamera;
}


#pragma mark - override


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    mTextureWidth = 0;
    mTextureHeight = 0;
    
    if (!mContext) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *sView = (GLKView *)[self view];
    [sView setContext:mContext];
    [self setPreferredFramesPerSecond:60];
    
    [sView setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    mSessionPreset = AVCaptureSessionPreset1280x720;
    
    [self setupGL];
    [self setupAVCapture];
    
    mIsStartedCamera = NO;
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self tearDownAVCapture];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == mContext) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Camera image orientation on screen is fixed
    // with respect to the physical camera orientation.
    
    if (interfaceOrientation == UIInterfaceOrientationPortrait)
        return YES;
    else
        return NO;
}


#pragma mark - delegate


- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
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
        
        [self setupBuffers];
        mIsStartedCamera = YES;
    }
    
    NSLog(@"capture frame");
    
    [self cleanUpTextures];
    
    // CVOpenGLESTextureCacheCreateTextureFromImage will create GLES texture
    // optimally from CVImageBufferRef.
    
    
    // Y-plane
    glActiveTexture(GL_TEXTURE0);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       mVideoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_LUMINANCE,
                                                       mTextureWidth,
                                                       mTextureHeight,
                                                       GL_LUMINANCE,
                                                       GL_UNSIGNED_BYTE,
                                                       0,
                                                       &mLumaTexture);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(mLumaTexture), CVOpenGLESTextureGetName(mLumaTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    // UV-plane
    glActiveTexture(GL_TEXTURE1);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       mVideoTextureCache,
                                                       pixelBuffer,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_LUMINANCE_ALPHA,
                                                       mTextureWidth/2,
                                                       mTextureHeight/2,
                                                       GL_LUMINANCE_ALPHA,
                                                       GL_UNSIGNED_BYTE,
                                                       1,
                                                       &mChromaTexture);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(mChromaTexture), CVOpenGLESTextureGetName(mChromaTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);
}


#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
//    if (_ripple)
//    {
//        [_ripple runSimulation];
//
//        // no need to rebind GL_ARRAY_BUFFER to _texcoordVBO since it should be still be bound from setupBuffers
//        glBufferData(GL_ARRAY_BUFFER, [_ripple getVertexSize], [_ripple getTexCoords], GL_DYNAMIC_DRAW);
//    }
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    if (mIsStartedCamera)
    {
        
        glClear(GL_COLOR_BUFFER_BIT);
        
        glDrawElements(GL_TRIANGLE_FAN, 4, GL_UNSIGNED_BYTE, 0);
        [mContext presentRenderbuffer:GL_RENDERBUFFER];
    }
}


#pragma mark - privates


- (void)tearDownGL
{
    [EAGLContext setCurrentContext:mContext];
    
    glDeleteBuffers(1, &mPositionBuffer);
    glDeleteBuffers(1, &mIndexBuffer);
    
    if (mProgram) {
        glDeleteProgram(mProgram);
        mProgram = 0;
    }
}


- (void)tearDownAVCapture
{
    [self cleanUpTextures];
    
    CFRelease(mVideoTextureCache);
}


- (void)cleanUpTextures
{
    if (mLumaTexture)
    {
        CFRelease(mLumaTexture);
        mLumaTexture = NULL;
    }
    
    if (mChromaTexture)
    {
        CFRelease(mChromaTexture);
        mChromaTexture = NULL;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(mVideoTextureCache, 0);
}


- (void)setupGL
{
    [EAGLContext setCurrentContext:mContext];
    
    [self loadShaders];
    
    glUseProgram(mProgram);
    
//    glUniform1i(uniforms[UNIFORM_Y], 0);
//    glUniform1i(uniforms[UNIFORM_UV], 1);
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
    [mSession setSessionPreset:mSessionPreset];
    
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
    [dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
                                                             forKey:(id)kCVPixelBufferPixelFormatTypeKey]]; // Necessary for manual preview
    
    // Set dispatch to be on the main thread so OpenGL can do things with the data
    [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    [mSession addOutput:dataOutput];
    [mSession commitConfiguration];
    
    [mSession startRunning];
}


- (void)setupBuffers
{
    vector<Vertex> sRectVertices(4);
    vector<Vertex>::iterator sVertex = sRectVertices.begin();
    
    sVertex->Position = Vector4(-1.0, -1.0, 1, 1);
    sVertex->TexturePosition = Vector2(1, 1);
    sVertex++;
    sVertex->Position = Vector4(-1.0, 1.0, 1, 1);
    sVertex->TexturePosition = Vector2(0, 1);
    sVertex++;
    sVertex->Position = Vector4(1.0, 1.0, 1, 1);
    sVertex->TexturePosition = Vector2(0, 0);
    sVertex++;
    sVertex->Position = Vector4(1.0, -1.0, 1, 1);
    sVertex->TexturePosition = Vector2(1, 0);

    glGenBuffers(1, &mPositionBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, mPositionBuffer);
    glBufferData(GL_ARRAY_BUFFER, sRectVertices.size() * sizeof(sRectVertices[0]), &sRectVertices[0], GL_STATIC_DRAW);
    
    vector<GLubyte> sIndices(4);
    vector<GLubyte>::iterator sIndex = sIndices.begin();
    
    *sIndex = 3;
    sIndex++;
    *sIndex = 2;
    sIndex++;
    *sIndex = 1;
    sIndex++;
    *sIndex = 0;
    
    glGenBuffers(1, &mIndexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sIndices.size() * sizeof(sIndices[0]), &sIndices[0], GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    
    const void *sTexCoordOffset = (GLvoid *)sizeof(Vector4);
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), sTexCoordOffset);
}


#pragma mark - OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    mProgram = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(mProgram, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(mProgram, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(mProgram, ATTRIB_VERTEX, "position");
    glBindAttribLocation(mProgram, ATTRIB_TEXCOORD, "texCoord");
    
    // Link program.
    if (![self linkProgram:mProgram]) {
        NSLog(@"Failed to link program: %d", mProgram);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (mProgram) {
            glDeleteProgram(mProgram);
            mProgram = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
//    uniforms[UNIFORM_Y] = glGetUniformLocation(mProgram, "SamplerY");
//    uniforms[UNIFORM_UV] = glGetUniformLocation(mProgram, "SamplerUV");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(mProgram, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(mProgram, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}


- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}


@end
