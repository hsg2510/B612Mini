//
//  SKCustomRenderingViewController.m
//  B612Mini
//
//  Created by JohnHong on 2018. 5. 8..
//  Copyright © 2018년 Naver. All rights reserved.
//

#import "SKCustomRenderingViewController.h"
#import "SKCustomRenderingView.h"


@implementation SKCustomRenderingViewController
{
    SKCustomRenderingView *mRenderingView;
}


#pragma mark - override


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    mRenderingView = [[SKCustomRenderingView alloc] initWithFrame:[[self view] bounds]];
    
    [[self view] addSubview:mRenderingView];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - public


- (void)startUpdating
{
    [mRenderingView startUpdating];
}


- (void)stopUpdating
{
    [mRenderingView stopUpdating];
}


@end
