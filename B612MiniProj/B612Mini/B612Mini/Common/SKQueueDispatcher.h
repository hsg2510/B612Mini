//
//  SKQueueDispatcher.h
//  B612Mini
//
//  Created by JohnHong on 2018. 2. 12..
//  Copyright © 2018년 Naver. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SKQueueDispatcher : NSObject


+ (id)sharedDispatcher;
- (void)runAsynchronouslyOnGLRenderingQueue:(void(^)(void))aBlock;


@end
