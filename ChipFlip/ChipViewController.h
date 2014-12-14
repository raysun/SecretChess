//
//  ViewController.h
//  ChipFlip
//
//  Created by Secret Chess on 5/31/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

#import "GameBoard.h"
#import "Chip.h"
#import "GameManager.h"
#import "StateManager.h"
#import "Constants.h"
#import "AIPlayer.h"
#import "LoadingView.h"
#import "MenuViewController.h"
#import <AVFoundation/AVFoundation.h>

#define NEW_GAME_OR_CANCEL 3
#define NEW_GAME 2
#define UNDO_ALERT 1

// one could argue this belongs to the gameboard but it's virtual
// but it's a view thing in the end
@interface OutlinesView : UIView
{
    NSArray *_outlines;
    float _red;
    float _green;
    float _blue;
    float _alpha;
    float _width;
}
-(id)initWithFrame:(CGRect)frame red:(float)red 
                           green:(float)green blue:(float)blue 
                           alpha:(float)alpha width:(float)width;

-(void)setColor:(float)red 
                           green:(float)green blue:(float)blue 
                           alpha:(float)alpha width:(float)width;
                           
@property (retain) NSArray *outlines;
@end

@interface ChipViewController : UIViewController  <UIAlertViewDelegate>
{
    IBOutlet UIImageView *_turnPlayer;
    IBOutlet UIImageView *_turnPlayer2;
    IBOutlet UIImageView *_underBar;
    IBOutlet UIImageView *_openbtn;
    IBOutlet UIImageView *_rankHint;
    IBOutlet UILabel *_msg;
    IBOutlet UILabel *_gameName;
}
@property UILabel *msg;
@property UILabel *gameName;
@property UIImageView *openbtn;
@property UIImageView *turnPlayer;
@property UIImageView *turnPlayer2;
@property UIImageView *underBar;
@property UIImageView *rankHint;

@end
