//
//  GameName.h
//  SecretChess
//
//  Created by julie m on 7/25/13.
//  Copyright (c) 2013 just4fun. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum choice
{
    Play,
    Nevermind
} GameChoice;

@interface GameName : UIViewController
{
    IBOutlet UITextField *_redplayer;
    IBOutlet UITextField *_blueplayer;

    IBOutlet UIButton *_ok;
    IBOutlet UIButton *_cancel;

    NSString *_you;
    NSString *_them;

    GameChoice _choice;

    BOOL _ipad;
}
@property GameChoice choice;

@property UITextField *redplayer;
@property UITextField *blueplayer;
@property UIButton *ok;
@property UIButton *cancel;
@property BOOL ipad;

@property (retain) NSString *you;
@property (retain) NSString *them;


-(IBAction)playGame;
-(IBAction)nevermind;

@end
