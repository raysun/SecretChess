//
//  SavedGame.h
//  SecretChess
//
//  Created by Secret Chess on 7/27/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum choice
{
    PlaySaved,
    PlayNew,
    None
} GameChoice;

@interface SavedGames : UIViewController <UITableViewDataSource,UITableViewDelegate>
{
    IBOutlet UITableView *_table;
    IBOutlet UIImageView *_name;
    IBOutlet UILabel *_tableTitle;

    IBOutlet UITextField *_redplayer;
    IBOutlet UITextField *_blueplayer;

    NSString *_you;
    NSString *_them;
    GameChoice _choice;

    IBOutlet UIButton *_ok;

    BOOL _ipad;
    BOOL _smallPhone;
    CGPoint _origin;

    NSArray *_games;
    int _selected;
    int _deleted;
}
@property BOOL ipad;
@property BOOL smallPhone;
@property CGPoint origin;

@property GameChoice choice;

@property UITextField *redplayer;
@property UITextField *blueplayer;

@property UIButton *ok;

@property int selected;
@property int deleted;
@property UITableView *table;
@property UIImageView *name;
@property UILabel *tableTitle;

@property (retain) NSArray *games;
@property (retain) NSString *you;
@property (retain) NSString *them;

-(IBAction)playGame;
@end
