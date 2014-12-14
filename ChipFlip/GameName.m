//
//  GameName.m
//  SecretChess
//
//  Created by julie m on 7/25/13.
//  Copyright (c) 2013 just4fun. All rights reserved.
//

#import "GameName.h"
#import "Constants.h"

@interface GameName ()

-(void)closeView;
@end

@implementation GameName

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        // Custom initialization
        self.ipad=NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}
- (void)viewWillAppear:(BOOL)animated
{
    if (self.ipad)
    {
        // hack since no xib for ipad
        double factor = 2;
        for (UIView *subview in self.view.subviews) 
        {
            CGRect box = subview.frame;
            box.size.width *= factor;
            box.size.height *= factor;
            box.origin.x = (box.origin.x * factor);
            box.origin.y = (box.origin.y  * factor);
            subview.frame=box;
        }
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(IBAction)playGame
{
    self.choice=Play;

    if (self.redplayer.text){
        self.you = [self.redplayer.text stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if (self.blueplayer.text) {
        self.them = [self.blueplayer.text stringByTrimmingCharactersInSet:
                     [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if ([self.you length] < 1){
        self.you = @"You";
    }
    if ([self.them length] < 1){
        self.them = @"Them";
    }

    self.redplayer.text = self.you;
    self.blueplayer.text = self.them;

    [self.view endEditing:YES];

    [self closeView];
}
-(IBAction)nevermind
{
    self.choice=Nevermind;
    [self closeView];
}

-(void)closeView
{
    [UIView animateWithDuration:MENU_SLIDE_DURATION
     delay:0.0 
     options:UIViewAnimationOptionTransitionNone
     animations:^{
            CGRect frame = self.view.frame;
            frame.origin.x = frame.size.width;
            frame.origin.y = frame.size.height;
            self.view.frame = frame;
        }
      completion:^(BOOL finished) {
            [self.view removeFromSuperview];
        }
     ];

    [[NSNotificationCenter defaultCenter] 
     postNotification:[NSNotification notificationWithName:GAME_NAME_CLOSE object:nil]];
}
@end
