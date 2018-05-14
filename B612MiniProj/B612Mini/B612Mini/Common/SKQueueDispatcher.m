//
//  SKQueueDispatcher.m
//  B612Mini
//
//  Created by JohnHong on 2018. 2. 12..
//  Copyright © 2018년 Naver. All rights reserved.
//

#import "SKQueueDispatcher.h"


const char* kRenderingQueueIdentifier = "openGLRenderingQueue";


@implementation SKQueueDispatcher
{
    dispatch_queue_t mGLRenderingQueue;
}


#pragma mark - init


+ (id)sharedDispatcher
{
    static SKQueueDispatcher *sSharedDispatcher = nil;
    static dispatch_once_t sOnceToken;
    
    dispatch_once(&sOnceToken, ^{
        sSharedDispatcher = [[self alloc] init];
    });
    
    return sSharedDispatcher;
}


- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        mGLRenderingQueue = dispatch_queue_create(kRenderingQueueIdentifier, DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}


#pragma mark - public


- (void)runAsynchronouslyOnGLRenderingQueue:(void(^)(void))aBlock
{
    dispatch_async(mGLRenderingQueue, aBlock);
}


@end
