//
//  GameManager.h
//  ChipFlip
//
//  Created by Secret Chess on 6/5/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Chip.h"
#import "GameBoard.h"
#import "Constants.h"
#include "Player.h"

#define IsOnePerson(gm) ((gm.gameType)==OneLocal)
#define IsTwoPeople(gm) ((gm.gameType)==TwoLocal)
#define IsRemoteGame(gm) ((gm.gameType)==RemoteGame)

typedef enum gameType
{
    OneLocal=1,          // against AI
    TwoLocal=2,          // local 2
    RemoteGame=3,
    NoGame
} GameType;

@interface GameManager : NSObject
{
    PlayerColor _currentPlayerColor;     // whose turn is it
    GameBoard *_gameBoard;               // the structure which knows and moves chips about
    UIView *_physicalBoard;

    int _totalRed;                       // may at sometime care about these stats
    int _totalBlue;
    BOOL _blueGeneral;
    BOOL _redGeneral;
    int _blueFaceDown;
    int _redFaceDown;

    GameType _gameType;  
}
@property GameType gameType;
@property PlayerColor currentPlayerColor;
@property UIView *physicalBoard;
@property (retain) GameBoard *gameBoard;
@property int totalBlue;
@property int totalRed;
@property int blueFaceDown;
@property int redFaceDown;
@property BOOL blueGeneral;
@property BOOL redGeneral;

-(BOOL)isGameOver;

// causes pieces to move; don't call if evaluteMove didn't return attackerWins!
-(void)executeMove:(Chip*)attacker defender:(Chip*)defender;

// simple state toggle between players
-(void)nextTurn;

// shortcuts to gameboard
-(Chip *)getItemAt:(CGPoint)rowCol;
-(Chip *)getItemAt:(int)row col:(int)col; // wraps gameBoard call of same sig
-(void)putItemAt:(Chip *)item row:(int)row col:(int)col;

// undo management
-(BOOL)canPop;
-(void)pop;  // undo
-(int)trim; // if memory warning, trim undo
-(void)push;
-(void)clearUndo;

//
// Used by AI and drag-handler
//
// color used is from attacker here since AI called
-(PlayerMove)evaluateMove:(Chip *)attacker row:(int)row col:(int)col;

// color must be supplied, ie drag-handler uses current-color for player turn validation;
// ignore geometry disregards 'legal move' requirements in order to determine 
// hierarchy between pieces
-(PlayerMove)evaluateMove:(Chip*)attacker defender:(Chip*)defender color:(PlayerColor)color
                                    ignoreGeometry:(BOOL)ignoreGeometry;

// Debug
-(void)dumpBoard:(NSString*)msg;

// AI support
-(int)valueOfChip:(Player)p color:(PlayerColor)color;

-(BOOL)isPieceTrapped:(int)row col:(int)col;
-(BOOL)isPieceTrapped:(Chip*)chip;

-(BOOL)isPieceDirectlyProtected:(Chip*)attacker defender:(Chip*)defender;
-(BOOL)isPieceDirectlyProtected:(int)row col:(int)col 
                                               defenderRow:(int)defenderRow
                                               defenderCol:(int)defenderCol;

-(void)prepareVirtualBoard;
-(void)restoreRealBoard;

-(void)peekBoard;

@end
