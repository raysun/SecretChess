//
//  AppDelegate.m
//  ChipFlip
//
//  Created by Secret Chess on 5/31/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import "AppDelegate.h"

#import "ChipViewController.h"
#import "Flurry.h"

static AppDelegate *_instance;

@interface AppDelegate()
{
    GKMatch *_match;
    BOOL _matchBegan;
}
@property GKMatch *match;
@property BOOL matchBegan;

-(void)authenticateLocalUser;

- (void)matchStarted;
- (void)matchEnded;
- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID;
@end

@implementation AppDelegate

+(AppDelegate*)instance {
    return _instance;
}

- (BOOL)application:(UIApplication *)application 
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Flurry startSession:@"YTZKF6F7ZMQQQRF69XV4"];
        
    ChipViewController *chipVC;    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Hiding the status bar See ChipViewController for prefersStatusBarHidden
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];

    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) 
    {
        // fix at some point (note landscape hacking) - having layout for all devices could
        // be better handled with modern constraints
        if (self.window.frame.size.height > 480) {
            chipVC = [[ChipViewController alloc] initWithNibName:@"ViewController_iPhone2" 
                      bundle:nil];
        }
        else {
            chipVC = [[ChipViewController alloc] initWithNibName:@"ViewController_iPhone" bundle:nil];
        }
    }
    else {
        chipVC = [[ChipViewController alloc] initWithNibName:@"ViewController_iPad" bundle:nil];
    }
    self.viewController = chipVC;

    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];

    // game center
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(authenticationChanged) 
     name:GKPlayerAuthenticationDidChangeNotificationName 
     object:nil];

    [self authenticateLocalUser];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

#pragma mark gamecenter
-(void)authenticationChanged 
{     
    if ([GKLocalPlayer localPlayer].isAuthenticated && !self.userAuthenticated) 
    {
        NSLog(@"Authentication changed: player authenticated.");
        self.userAuthenticated = TRUE;           
    } 
    else if (![GKLocalPlayer localPlayer].isAuthenticated && self.userAuthenticated) 
    {
        NSLog(@"Authentication changed: player not authenticated");
        self.userAuthenticated = FALSE;
    } 
}
-(void)authenticateLocalUser
{
    NSLog(@"Authenticating local user...");

    if ([GKLocalPlayer localPlayer].authenticated == NO) 
    {     
        NSLog(@"Setting auth handler...");

        [GKLocalPlayer localPlayer].authenticateHandler = 
            ^(UIViewController *viewController,NSError *error) 
            {
                if ([GKLocalPlayer localPlayer].authenticated) { 
                    NSLog(@"already authenticated");
                } 
                else if (viewController) 
                {
                    NSLog(@"present login");
                    [self.viewController presentViewController:viewController 
                     animated:YES completion:nil];
                } 
                else {
                    NSLog(@"ugh");
                } 
            };        
    } 
    else {
        NSLog(@"Already authenticated!");
    }
}
#pragma mark GKMatchDelegate
- (void)matchStarted
{
}
- (void)matchEnded
{
}
-(void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
{
    if (self.match != match) 
    {
        NSLog(@"match:didReceiveData what match is this?");
        return;
    }
 
    // do something useful
    //[delegate match:match didReceiveData:data fromPlayer:playerID];
}
// The player state changed (eg. connected or disconnected)
- (void)match:(GKMatch *)theMatch player:(NSString *)playerID 
                          didChangeState:(GKPlayerConnectionState)state 
{   
    if (self.match != theMatch) 
    {
        NSLog(@"match: theMatch what match is this?");
        return;
    }
 
    switch (state) 
    {
     case GKPlayerStateConnected: 
         // handle a new player connection.
         NSLog(@"Player connected!");
         
         if (!self.matchBegan && theMatch.expectedPlayerCount == 0) {
             NSLog(@"Ready to start match!");
         }
         
         break; 
     case GKPlayerStateDisconnected:
         // a player just disconnected. 
         NSLog(@"Player disconnected!");
         self.matchBegan = NO;

         //[delegate matchEnded];

         break;
    }                     
}

// The match was unable to connect with the player due to an error.
- (void)match:(GKMatch *)theMatch connectionWithPlayerFailed:(NSString *)playerID 
                                                   withError:(NSError *)error 
{ 
    if (self.match != theMatch) 
    {
        NSLog(@"match: connectionWithPlayerFailed what match is this?");
        return;
    }
    NSLog(@"Failed to connect to player with error: %@", error.localizedDescription);
    self.matchBegan = NO;

    //[delegate matchEnded];
}
 
// The match was unable to be established with any players due to an error.
- (void)match:(GKMatch *)theMatch didFailWithError:(NSError *)error 
{ 
    if (self.match != theMatch) 
    {
        NSLog(@"match: didFailWithError what match is this?");
        return;
    }
 
    NSLog(@"Match failed with error: %@", error.localizedDescription);
    self.matchBegan = NO;
    //[delegate matchEnded];
}

- (void)findMatchWithMinPlayers
{
    self.matchBegan = NO;
    self.match = nil;
    [self.viewController dismissViewControllerAnimated:NO completion:nil];
 
    GKMatchRequest *request = [[GKMatchRequest alloc] init]; 
    request.minPlayers = 2;     
    request.maxPlayers = 2;
 
    GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
    mmvc.matchmakerDelegate = self;
 
    //    [self.viewController presentModalViewController:mmvc animated:YES];
    [self.viewController presentViewController:mmvc animated:YES  completion:nil];
}

#pragma mark GKMatchmakerViewControllerDelegate
 
// The user has cancelled matchmaking
- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController {
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}
 
// Matchmaking has failed with an error
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController 
                didFailWithError:(NSError *)error 
{
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"Error finding match: %@", error.localizedDescription);    
}
 
// A peer-to-peer match has been found, the game should start
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController 
                    didFindMatch:(GKMatch *)theMatch 
{
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    self.match = theMatch;

    if (!self.matchBegan && theMatch.expectedPlayerCount == 0) {
        NSLog(@"Ready to start match!");
    }
}
@end
