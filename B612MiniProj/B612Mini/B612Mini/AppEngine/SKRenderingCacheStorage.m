//
//  SKRenderingCacheStorage.m
//  B612Mini
//
//  Created by JohnHong on 2018. 2. 12..
//  Copyright © 2018년 Naver. All rights reserved.
//

#import "SKRenderingCacheStorage.h"
//#import "SKAppEngine.h"


@implementation SKRenderingCacheStorage
{
    CVOpenGLESTextureCacheRef mCoreVideoTextureCacheRef;
    GLuint mCoreVideoTexture;
}


@synthesize coreVideoTexture = mCoreVideoTexture;


#pragma mark - init


+ (id)sharedRenderingCacheStorage
{
    static SKRenderingCacheStorage *sSharedStorage = nil;
    static dispatch_once_t sOnceToken;
    
    dispatch_once(&sOnceToken, ^{
        sSharedStorage = [[self alloc] init];
    });
    
    return sSharedStorage;
}


- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        mCoreVideoTextureCacheRef = NULL;
    }
    
    return self;
}


#pragma mark - public


- (CVOpenGLESTextureCacheRef)coreVideoTextureCacheRef
{
//    if (mCoreVideoTextureCacheRef == NULL)
//    {
//        CVReturn sErr = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [[SKAppEngine sharedAppEngine] context], NULL, &mCoreVideoTextureCacheRef);
//        
//        if (sErr)
//        {
//            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", sErr);
//        }
//    }
    
    return mCoreVideoTextureCacheRef;
}
    

@end
