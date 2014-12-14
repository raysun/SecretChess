//
//  StateManager.m
//  ChipFlip
//
//  Created by Secret Chess on 6/8/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import "Constants.h"
#import "StateManager.h"
#import "SimpleZip.h"

static GameType _gameType;

@interface StateManager ()
+(NSString *)rowColAsString:(int)row col:(int)col;
+(NSDictionary*)savedGameBoard:(NSString*)file;
+(void)saveGameBoard:(NSDictionary*)gameBoard file:(NSString*)file;
+(NSString*)savedGameFolder:(NSString*)file;
@end


@implementation StateManager

+(NSString*)savedGameFolder:(NSString*)file
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory 
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsPath, file];
    return filePath;
}

+(void)saveGameBoard:(NSDictionary*)gameBoard file:(NSString*)file
{
    NSData *data = [SimpleZip compress:[NSKeyedArchiver archivedDataWithRootObject:gameBoard]];
    [data writeToFile:[StateManager savedGameFolder:file] atomically:YES];
    data = nil;
}
+(NSDictionary*)savedGameBoard:(NSString*)file
{
    @autoreleasepool {
        NSData *data = [NSData dataWithContentsOfURL:
                        [NSURL fileURLWithPath:[StateManager savedGameFolder:file]]];
        NSDictionary* gameBoard = 
            (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:[SimpleZip uncompress:data]];
        return gameBoard;
    }
}

+(NSString *)rowColAsString:(int)row col:(int)col {
    return [NSString stringWithFormat:@"%d,%d", row, col];
}

//@todo defaulting to local, should supply set
+(NSArray *)savedGames
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory 
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    NSArray *files = [fm contentsOfDirectoryAtPath:documentsPath error:&error];

    NSMutableArray *games = [[NSMutableArray alloc] init];

    for (NSString *file in files)
    {
        if ([file hasSuffix:@".game"]) 
        {
            NSDictionary *savedBoard = [self savedGameBoard:file];
            if (savedBoard)
            {
                AGame *aGame = [[AGame alloc]init];
                aGame.name = [file stringByReplacingOccurrencesOfString:@".game" withString:@""];
                aGame.detail=@"";

                NSString *t = (NSString*)[savedBoard objectForKey:@"gameType"];
                if (t) //better be here
                {
                    int type = [t intValue];
                    switch (type)
                    {
                     case OneLocal:
                         aGame.detail = ONE_LOCAL;
                         break;
                     case TwoLocal:
                         aGame.detail = TWO_LOCAL;
                         break;
                     case RemoteGame:
                         aGame.detail = TWO_NETWORK;
                         break;
                    }
                }
                savedBoard=nil;
                [games addObject:aGame];
                aGame=nil;
            }
        }
    }
    files = nil;
    return games;
}

+(void)saveGameState:(GameManager*)gameManager type:(GameType)type 
        gameOver:(BOOL)gameOver name:(NSString*)name
{
    NSMutableDictionary *savedBoard = [NSMutableDictionary dictionaryWithCapacity:ROWS];
    [savedBoard setObject:VERSION forKey:@"version"];
    [savedBoard setObject:[NSString stringWithFormat:@"%d", gameOver ? 1:0] forKey:@"gameOver"];
    [savedBoard setObject:[NSString stringWithFormat:@"%d", type] forKey:@"gameType"];

    if (type==OneLocal) 
    {
        name = USER_VS_GAME;
        [savedBoard setObject:name forKey:@"nameOfGame"];
    }
    else {
        [savedBoard setObject:name forKey:@"nameOfGame"];
    }
    
    // rule engine/current player
    [savedBoard setObject:[NSString stringWithFormat:@"%d", gameManager.currentPlayerColor] 
                   forKey:@"currentColor"];
    
    // gameboard as dictionary. 
    if (!gameOver)
    {
        for (int row=0; row < ROWS; row++)
        {
            for (int col=0; col < COLS;col++)
            {
                Chip *chip = [gameManager getItemAt:row col:col];
                if (chip && chip.player!=Empty)
                {
                    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:chip];
                    NSString *key = [StateManager rowColAsString:row col:col];
                    [savedBoard setObject:data forKey:key];
                    data=nil;
                }
                else {
                    // empty slot, sparse saves room
                }
            }
        }
    }

    if (type==RemoteGame) {
        NSLog(@"wtf don't know who i'm playing");
    }
    NSString *file = [NSString stringWithFormat:@"%@.game", name];
    [StateManager saveGameBoard:savedBoard file:file];
    savedBoard = nil;
}
+(GameType)savedGameType{
    return _gameType;
}
+(void)deleteGameState:(NSString *)name
{
   NSString *file = [NSString stringWithFormat:@"%@.game", name];
   file = [StateManager savedGameFolder:file];

   NSError *error;
   NSFileManager *fm = [NSFileManager defaultManager];
   [fm removeItemAtPath:file error:&error];
}

+(BOOL)restoreGameState:(GameManager*)gameManager name:(NSString*)name
{
    // should be from a list of saved states
    if (!name) {
        return NO;
    }
    NSString *file = [NSString stringWithFormat:@"%@.game", name];
    NSDictionary *savedBoard = [self savedGameBoard:file];
    NSString *t;

    if (!savedBoard){
        return NO;
    }

    _gameType = OneLocal;
    t = (NSString*)[savedBoard objectForKey:@"gameType"];
    if (t) //better be here
    {
        GameType type = [t intValue];
        if (type >= OneLocal && type <= RemoteGame){
            _gameType = type;
        }
    }

    if (_gameType==RemoteGame) 
    {
        savedBoard=nil;
        NSLog(@"wtf don't know who i'm playing");
        return NO;
    }

    t = (NSString*)[savedBoard objectForKey:@"currentColor"];
    if (t) {//better be here
        gameManager.currentPlayerColor = [t intValue];
    }

    for (int row=0; row < ROWS; row++)
    {
        for (int col=0; col < COLS;col++)
        {
            NSString *key = [StateManager rowColAsString:row col:col];
            NSData *rawChip = [savedBoard objectForKey:key];
            if (rawChip)
            {
                Chip *chip = [NSKeyedUnarchiver unarchiveObjectWithData:rawChip];
                if (chip)
                {
                    // replacing the blank cell with this one
                    Chip *existing = [gameManager getItemAt:row col:col];
                    chip.cellBounds = existing.cellBounds;
                    [gameManager putItemAt:chip row:row col:col];
                    chip = nil;
                    [existing removeFromBoard];
                }
            }
        }
    }

    [gameManager.gameBoard syncBoardCells];
    savedBoard=nil;
    return YES;
}

@end
@implementation AGame
@end
