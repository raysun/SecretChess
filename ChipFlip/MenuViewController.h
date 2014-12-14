//
//  MenuViewController.h
//  SecretChess
//
//  Created by Secret Chess on 6/24/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"

typedef enum button
{
    Players1,
    Players2Pick,
    Players2,
    PlayersNetwork,
    Cancel,
    Undo,
    GameHelp,
    Peek
} ButtonPressed;

@interface MenuViewController : UIViewController
{
    IBOutlet UIImageView *_undo;
    IBOutlet UIImageView *_help;

    IBOutlet UIImageView *_playersNetwork;
    IBOutlet UIImageView *_players1;
    IBOutlet UIImageView *_players2;
    IBOutlet UIImageView *_cancel;
    IBOutlet UIImageView *_musicBtn;
    IBOutlet UIImageView *_peek;
    
    ButtonPressed _button;
    BOOL _musicIsOn;

    BOOL _ipad;
    BOOL _smallPhone;
    CGPoint _origin;
}
@property CGPoint origin;
@property BOOL ipad;
@property BOOL smallPhone;
@property UIImageView *players1;
@property UIImageView *players2;
@property UIImageView *playersNetwork;
@property UIImageView *cancel;
@property UIImageView *undo;
@property UIImageView *help;
@property UIImageView *musicBtn;
@property UIImageView *peek;

@property ButtonPressed button;
@property BOOL musicIsOn;

-(IBAction)player1Pressed;
-(IBAction)player2Pressed;
-(IBAction)playerNetworkPressed;
-(IBAction)cancelPressed;
-(IBAction)undoPressed;
-(IBAction)gameHelpPressed; // vs some online?
-(IBAction)musicToggle;
-(IBAction)peekPressed;

-(void)addToWithEffect:(UIView*)parent;
-(void)disableButton:(UIImageView*)someBtn comingSoon:(BOOL)comingSoon;
-(void)enableButton:(UIImageView*)someBtn;

-(void)updateMusicButtons;
@end
