//
//  AppDelegate.h
//  ChipFlip
//
//  Created by Secret Chess on 5/31/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import <GameKit/GKMatch.h>


@class ChipViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate,
    GKMatchmakerViewControllerDelegate, GKMatchDelegate>
{
    BOOL _userAuthenticated;
}
@property BOOL userAuthenticated; 
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ChipViewController *viewController;

+(AppDelegate*)instance;

- (void)findMatchWithMinPlayers;

@end
