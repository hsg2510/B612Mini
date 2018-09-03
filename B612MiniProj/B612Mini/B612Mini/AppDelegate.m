//
//  AppDelegate.m
//  B612Mini
//
//  Created by JohnHong on 2018. 2. 8..
//  Copyright © 2018년 Naver. All rights reserved.
//

#import "AppDelegate.h"
#import "SKCustomRenderingViewController.h"


@implementation AppDelegate
{
    UIWindow *mWindow;
    SKCustomRenderingViewController *mViewController;
}


@synthesize window = mWindow;


- (BOOL)application:(UIApplication *)aApplication didFinishLaunchingWithOptions:(NSDictionary *)aLaunchOptions
{
    mWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//    ViewController *sViewController = [[ViewController alloc] initWithNibName:nil bundle:nil];
//    mViewController = [[SKRenderingViewController alloc] initWithNibName:nil bundle:nil];
    mViewController = [[SKCustomRenderingViewController alloc] initWithNibName:nil bundle:nil];
    
    [mWindow setRootViewController:mViewController];
    [mWindow makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication*)application
{
    [mViewController stopUpdating];
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
    [mViewController stopUpdating];
}

- (void)applicationWillEnterForeground:(UIApplication*)application
{
    [mViewController startUpdating];
}

- (void)applicationDidBecomeActive:(UIApplication*)application
{
    [mViewController startUpdating];
}

- (void)applicationWillTerminate:(UIApplication*)application
{
    [mViewController stopUpdating];
}

@end
