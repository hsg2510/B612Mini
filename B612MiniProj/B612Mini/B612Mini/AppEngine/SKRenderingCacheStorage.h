//
//  SKRenderingCacheStorage.h
//  B612Mini
//
//  Created by JohnHong on 2018. 2. 12..
//  Copyright © 2018년 Naver. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>


@interface SKRenderingCacheStorage : NSObject


@property (nonatomic, assign) GLuint coreVideoTexture;

+ (id)sharedRenderingCacheStorage;
- (CVOpenGLESTextureCacheRef)coreVideoTextureCacheRef;


@end
