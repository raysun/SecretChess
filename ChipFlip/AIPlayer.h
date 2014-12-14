//
//  AIPlayer.h
//  ChipFlip
//
//  Created by Secret Chess on 6/14/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameBoard.h"
#import "GameManager.h"
#import "Player.h"          // enums etc
#import "Chip.h"          // enums etc

@interface Score:NSObject
{
    CGPoint _attacker;
    CGPoint _defender;
    int _value;
}
@property CGPoint attacker;
@property CGPoint defender;
@property int value;
@end

@interface AIPlayer : NSObject
{
    Chip *_bestAttacker;
    Chip *_bestDefender;
    GameManager *_gameManager;
}
@property Chip *bestAttacker;
@property Chip *bestDefender;

@property GameManager *gameManager;

// make next move as blue on the board; fills in the player that attacked and the defender;
// if returns false, attacker/defender not valid
-(BOOL)makeMove;

-(Chip*)getAttacker;
-(Chip*)getDefender;

@end
