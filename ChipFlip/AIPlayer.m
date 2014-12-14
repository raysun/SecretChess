//
//  AIPlayer.m
//  ChipFlip
//
//  Created by Secret Chess on 6/14/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import "AIPlayer.h"

#define MAX_DEPTH 3

#define MassageScore(x) ((x)/5)       // some ray thing :)

#define NO_PLAYER CGPointMake(-1,-1)
#define GET_PLAYER(p) [self.gameManager getItemAt:(p)]
#define IS_PLAYER(p) ((p).x != -1 && (p).y != -1)

@implementation Score
-(void)dealloc
{
}
-(id)init 
{
    if ((self=[super init])) {
        self.attacker = self.defender = NO_PLAYER;
    }
    return self;
}
@end

/*
 * Attempt at abstracting the move selection from the rest of the stuff but it
 * is still currently dependent on shared files
 */ 

@interface AIPlayer ()
{
    CGPoint _attacker;
    CGPoint _defender;
}
@property CGPoint attacker;
@property CGPoint defender;

-(Chip*)flipSomething;
-(Chip*)flipSomethingAndLookForPossibleCannon:(BOOL)hopeForCannon;
-(BOOL)isTrappedNonCannonEnemy:(Chip*) chip;
-(void)scoreMoves:(Chip *)attacker moves:(NSMutableArray*)moves 
              row:(int)row col:(int)col allowEmpty:(BOOL)allowEmpty;
-(NSArray*)findMoves:(PlayerColor)color;
-(float)makeMoveWithDepth:(int)depth 
                   player:(PlayerColor)player 
                   bestScores:(NSMutableArray*)bestScores;

-(void)debugMove:(Score *)score msg:(NSString*)msg;
-(float)getTotalValueOfAllVisibleChipsOfColor:(PlayerColor)color;
-(NSString*)playerMoveToString:(PlayerMove)p;
@end


@implementation AIPlayer

-(Chip*)getAttacker {
    return GET_PLAYER(self.attacker);
}
-(Chip*)getDefender {
    return GET_PLAYER(self.defender);
}

-(id)init
{
    if (self=[super init]) {
        self.attacker = self.defender = NO_PLAYER;
    }
    return self;
}

-(NSString*)playerMoveToString:(PlayerMove)p
{
    NSString *strings[] = {
        @"AttackerWins",
        @"DefenderWins",
        @"EmptyTaken",
        @"NotYourTurn",
        @"IllegalMove",
        @"SameSpot",
        @"OutOfBounds"
    };
    
    return strings[p];
}

-(NSString*)playerColorToString:(PlayerColor)p
{
    NSString *strings[] = {
        @"None",
        @"Red",
        @"BlueAI"
    };
    return strings[p];
}


-(void)scoreMoves:(Chip *)attacker moves:(NSMutableArray*)moves row:(int)row col:(int)col
       allowEmpty:(BOOL)allowEmpty
{
    PlayerMove moveResult = [self.gameManager evaluateMove:attacker row:row col:col];
    
    if (moveResult==AttackerWins || (moveResult==EmptyTaken && allowEmpty))
    {
        // defender value is the score for this move
        Score *score = [[Score alloc] init];
        score.attacker = CGPointMake(attacker.row, attacker.col);
        score.defender = CGPointMake(row, col);
        
        Chip *defender = [[self.gameManager getItemAt:row col:col] clone:YES];

        score.value = [self.gameManager valueOfChip:defender.player color:attacker.color];

        [moves addObject:score];
        score = nil;
    }
}
-(float)getTotalValueOfAllVisibleChipsOfColor:(PlayerColor)color
{
    float sum = 0;
    
    // just looking for face up pieces, which are good for me
    for (int i = 0; i < ROWS; i++)
    {
        for (int j = 0; j < COLS; j++)
        {
            Chip *chip = [self.gameManager getItemAt:i col:j];
            if (chip && chip.color==color && chip.state==FACE_UP) {
                sum += [self.gameManager valueOfChip:chip.player color:chip.color];
            }
        }
    }
    return sum;
}

-(NSArray*)findMoves:(PlayerColor)color
{
    NSMutableArray *moves = [[NSMutableArray alloc] initWithCapacity:ROWS*COLS];

    // score - for every chip, check if face up and blue. 
    // just brute force rubbish!
    for (int i = 0; i < ROWS; i++)
    {
        for (int j = 0; j < COLS; j++)
        {
            Chip *chip = [self.gameManager getItemAt:i col:j];
            if (chip && chip.color==color && chip.state==FACE_UP)
            {
                if (chip.player==Artillery) 
                {
                    // find all legal jumping moves first
                    for (int k = 1; k <= COLS; k++)
                    {
                        [self scoreMoves:chip moves:moves row:i-k col:j allowEmpty:NO];
                        [self scoreMoves:chip moves:moves row:i+k col:j allowEmpty:NO];
                        [self scoreMoves:chip moves:moves row:i col:j-k allowEmpty:NO];
                        [self scoreMoves:chip moves:moves row:i col:j+k allowEmpty:NO];
                    }
                }
                // standard 1 place move + find empty
                [self scoreMoves:chip moves:moves row:i-1 col:j allowEmpty:YES];
                [self scoreMoves:chip moves:moves row:i+1 col:j allowEmpty:YES];
                [self scoreMoves:chip moves:moves row:i col:j-1 allowEmpty:YES];
                [self scoreMoves:chip moves:moves row:i col:j+1 allowEmpty:YES];
            }
        }
    }

    if ([moves count] < 1)
    {
        // when flipping, try to find a cannon that can attack a trapped enemy
        Chip *chip = [self flipSomethingAndLookForPossibleCannon:YES];
        if (!chip) {
            chip = [self flipSomethingAndLookForPossibleCannon:NO];
        }
        
        if (chip)
        {
            Score *score = [[Score alloc] init];
            score.attacker = CGPointMake(chip.row, chip.col);
            score.defender = NO_PLAYER;
            score.value = [self.gameManager valueOfChip:chip.player color:color];
            [moves addObject:score];
        }
    }

    return moves;
}
-(void)debugMove:(Score *)score msg:(NSString*)msg
{
    if (LOG) 
    {
        NSString *debug = @"*********** wtf no moves **********";
        if (IS_PLAYER(score.attacker)) 
        {
            Chip *chip = [self.gameManager getItemAt:score.attacker];
            debug = [NSString stringWithFormat:@"%@", [chip fullName]];
            
            if (IS_PLAYER(score.defender))
            {
                chip = [self.gameManager getItemAt:score.defender];
                debug = [NSString stringWithFormat:@"%@ -> %@", debug, [chip fullName]];           
                NSLog(@"%@ move: %@", msg, debug);
            }
            else {
                NSLog(@"%@ flip: %@", msg, debug);
            }
        }
        else {
            NSLog(@"%@", debug);
        }
    }
}

// brainless more or less 
-(BOOL)makeMove
{
    self.attacker = self.defender = NO_PLAYER;
    NSMutableArray *scores = [[NSMutableArray alloc] init];
    [self.gameManager prepareVirtualBoard];

    [self.gameManager 
     dumpBoard:@"\n------------------------------------------------\nboard before blue"];

    if (LOG)
    {
        float result = [self makeMoveWithDepth:0 player:BLUE bestScores:scores];
        NSLog(@"result %f", result);
    }
    else {
        [self makeMoveWithDepth:0 player:BLUE bestScores:scores];
    }

    // getting here hopefully means 'scores' has stuff
    float points = -90000;
    for (Score *score in scores)
    {
        if (score.value > points) 
        {
            points = score.value;
            self.attacker = score.attacker;
            self.defender = score.defender;
            
            [self debugMove:score msg:@"chosing from"];
        }
    }
    
    // expectation is undo stack is at 0
    if ([self.gameManager canPop]) {
//        NSLog(@"error - undo stack not empty on virtual board shutdown!");
    }
    [self.gameManager restoreRealBoard];
    [self.gameManager dumpBoard:@"real board restored"];

    //////////////// just for debug /////////////////////
    Score *score = [[Score alloc] init];
    score.attacker = self.attacker;
    score.defender = self.defender;
    [self debugMove:score msg:@"selected"];
    score=nil;
    /////////////////////////////////////////////////////

    BOOL result = (IS_PLAYER(self.defender) || IS_PLAYER(self.attacker));
    return result;
}
// always start at now board, walk each piece down depth N and score
-(float)makeMoveWithDepth:(int)depth player:(PlayerColor)player bestScores:(NSMutableArray*)bestScores
{
    float highest = -999999;
    float boardScore = 0;
    PlayerColor attackingPlayer = player;
    PlayerColor defendingPlayer = (attackingPlayer==BLUE ? RED : BLUE);
    NSArray *attackerMoveList = [self findMoves:attackingPlayer];
    NSArray *defenderMoveList = [self findMoves:defendingPlayer];
    
    for (Score *score in attackerMoveList)
    {
        if (score.value > 0) {
            boardScore += MassageScore(score.value);
        }
    }
    boardScore += [self getTotalValueOfAllVisibleChipsOfColor:attackingPlayer];

    for (Score *score in defenderMoveList)
    {
        if (score.value > 0) {
            boardScore -= MassageScore(score.value);
        }
    }
    boardScore -= [self getTotalValueOfAllVisibleChipsOfColor:defendingPlayer];

    if (depth == MAX_DEPTH) {
        return boardScore;
    }

    // see how score is after all thisPlayer's moves performed

    // puke
    for (int i = 0; i < 2; i++)
    {
        BOOL force = (i > 0);

        // sometimes no move has a positive value but no move is not allowed
        for (Score *score in attackerMoveList)
        {
            if ((force || score.value > 0) && IS_PLAYER(score.attacker))// && score.defender)
            {
                if (LOG) {
                    NSLog(@"pushing");
                }
                [self.gameManager push];
                
                [self.gameManager dumpBoard:@"before executeMove"];
                
                // do the move
                [self debugMove:score msg:[NSString stringWithFormat:@"evaluting depth:%d", depth]];
                [self.gameManager executeMove:GET_PLAYER(score.attacker) 
                 defender:GET_PLAYER(score.defender)];
                
                [self.gameManager dumpBoard:@"after executeMove"];
                
                // get the score
                float newScore = [self makeMoveWithDepth:depth+1 player:defendingPlayer 
                                  bestScores:bestScores];
                
                // restored
                [self.gameManager pop];
                
                [self.gameManager dumpBoard:@"after pop"];
                
                // kill me, split this better later
                if (depth==0)
                {
                    if (newScore > highest)
                    {
                        highest = newScore;                    
                        [bestScores addObject:score];
                        boardScore = highest;
                    }
                }
            }
        }

        // no need for additional low-quality moves
        if ([bestScores count] > 0) {
            break;
        }
    }

    return boardScore;
}

-(void)dealloc
{
    self.gameManager=nil;
}

// fallback lame flip a chip
-(Chip*)flipSomething
{
    int row = rand() % ROWS;
    int col = rand() % COLS;

    for (int i = 0; i < ROWS; i++)
    {
        for (int j = 0; j < COLS; j++)
        {
            Chip *chip = [self.gameManager getItemAt:row col:col];
            
            if (chip && chip.player!=Empty && chip.state==FACE_DOWN) {
                return chip;
            }
            col = (col >= COLS ? 0 : col+1);
        }
        row = (row >= ROWS ? 0 : row+1);
    }
    return nil;
}

// Looks for a piece to flip - if the enemy is trapped, try to find your cannon to attack him, else just open a random piece
// TODO: shouldn't be random, should be smart
-(Chip*)flipSomethingAndLookForPossibleCannon:(BOOL)hopeForCannon
{
    int rowsScanned=0;
    int i = rand() % ROWS;
    int j = rand() % COLS;
    
    while (rowsScanned < ROWS)
    {
        int colsScanned=0;
        while (colsScanned < COLS)
        {
            Chip *chip = [self.gameManager getItemAt:i col:j];
            
            if (chip)
            {
                if (hopeForCannon==YES)
                {
                    // Look for a cannon that is upside down, 2 away from a trapped enemy
                    
                    /* BUGBUG: it shouldn't be looking for 2 away, it should be looking for
                     // a legal cannon attack since right now it will open if it is merely
                     // 2 spaces away & there's nothing in between
                     */
                    Chip *chipToAttack;
                    if (chip.state==FACE_DOWN)
                    {
                        chipToAttack = [self.gameManager getItemAt:i+2 col:j];
                        if ([self isTrappedNonCannonEnemy:chipToAttack]){
                            return chip;
                        }
                        chipToAttack = [self.gameManager getItemAt:i col:j+2];
                        if ([self isTrappedNonCannonEnemy:chipToAttack]) {
                            return chip;
                        }
                        chipToAttack = [self.gameManager getItemAt:i-2 col:j];
                        if ([self isTrappedNonCannonEnemy:chipToAttack]){
                            return chip;
                        }
                        chipToAttack = [self.gameManager getItemAt:i col:j-2];
                        if ([self isTrappedNonCannonEnemy:chipToAttack]){
                            return chip;
                        }
                    }
                }
                else if (chip.state==FACE_DOWN) {
                    return chip;
                }
            }
            j++;
            if (j == COLS) {
                j = 0;
            }
            colsScanned++;
        }
        
        i++;
        if (i > ROWS) {
            i = 0;
        }
        rowsScanned++;
    }
    return nil;
}

// See if this piece is a trapped enemy and not a cannon
-(BOOL)isTrappedNonCannonEnemy:(Chip*) chip
{
    if (chip)
    {
        if (chip.color!=self.gameManager.currentPlayerColor && chip.state==FACE_UP &&
            chip.player != Artillery &&
            [self.gameManager isPieceTrapped:chip])
        {
            return YES;
        }
    }
    return NO;
}

@end
