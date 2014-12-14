//
//  StateManager.h
//  ChipFlip
//
//  Created by Secret Chess on 6/8/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Chip.h"
#import "GameBoard.h"
#import "GameManager.h"

@interface AGame : NSObject
{
    NSString *_name;
    NSString *_detail;
}
@property (retain) NSString *name;
@property (retain) NSString *detail;
@end


@interface StateManager : NSObject
{
}

+(void)saveGameState:(GameManager*)gameManager type:(GameType)type gameOver:(BOOL)gameOver
                name:(NSString*)name;
// @todo deal with local and remote saved games
+(BOOL)restoreGameState:(GameManager*)gameManager name:(NSString *)name;
+(void)deleteGameState:(NSString *)name;
+(NSArray *)savedGames;

+(GameType)savedGameType;
@end
