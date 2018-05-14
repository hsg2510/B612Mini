//
//  SKRenderingViewController.m
//  B612Mini
//
//  Created by JohnHong on 2018. 5. 7..
//  Copyright © 2018년 Naver. All rights reserved.
//

#import "SKRenderingViewController.h"
#import "SKRenderingView.h"


@implementation SKRenderingViewController
{
    SKRenderingView *mRenderingView;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    mRenderingView = [[SKRenderingView alloc] initWithFrame:[[self view] bounds]];
    
    [[self view] addSubview:mRenderingView];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


@end
