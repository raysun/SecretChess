//
//  GameManager.m
//  ChipFlip
//
//  Created by Secret Chess on 6/5/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import "GameManager.h"
#import "Player.h"

@interface GameManager ()
{
    NSMutableArray * _savedMoves;
    GameBoard *_realBoard;
}
@property (retain) NSMutableArray * savedMoves;
@property (retain) GameBoard *realBoard;

-(BOOL)specialArtilleryRule:(Chip*)attacker defender:(Chip*)defender 
                   ignoreGeometry:(BOOL)ignoreGeometry;
-(BOOL)noMove:(Chip*)chip row:(int)row col:(int)col;
@end

/*
 * Simple engine which manages gameplay things
 */
@implementation GameManager

-(id)init
{
    if (self=[super init]) 
    {
        self.currentPlayerColor=NONE;
        self.gameType = NoGame;
    }
    return self;
}

-(void)dumpBoard:(NSString*)msg
{
    if (LOG)
    {
        NSString *line = [msg stringByAppendingString:@"\n"];
        
        for (int row=0; row < ROWS; row++)
        {
            line = [NSString stringWithFormat:@"%@(%d)", line, row];
            for (int col=0; col < COLS;col++) {
                line = [NSString stringWithFormat:@"%@|%@", line, [self getItemAt:row col:col]];
            }
            line = [line stringByAppendingString:@"\n"];
        }
        NSLog(@"%@\n", line);
    }
}

// color refers to the color of the attacker
-(int)valueOfChip:(Player)p color:(PlayerColor)color
{
    switch (p)
    {
     case General:
         return 7;
     case Advisor:
         return 6;
     case Elephant:
         return 5;
     case Chariot:
         return 4;
     case Horse:
         return 3;
     case Artillery:
         return 5;

     case Infantry:
         if (color==BLUE)
         {
             if (self.redGeneral && !self.blueGeneral){
                 return 3;
             }
         }
         else 
         {
             if (!self.redGeneral && self.blueGeneral){
                 return 3;
             }
         }
         return 1;

     case Empty:
         return -1;
     default:
         return 0;
    }
}
-(Chip *)getItemAt:(CGPoint)rowCol {
    return [self.gameBoard getItemAt:rowCol.x col:rowCol.y];
}
-(Chip *)getItemAt:(int)row col:(int)col{
    return [self.gameBoard getItemAt:row col:col];
}
-(void)putItemAt:(Chip *)item row:(int)row col:(int)col{
    return [self.gameBoard putItemAt:item row:row col:col];
}

// returns the state when the attacker tries to displace the defender;
// attacker, defender must not be nil
-(PlayerMove)evaluateMove:(Chip*)attacker defender:(Chip*)defender color:(PlayerColor)color
                                    ignoreGeometry:(BOOL)ignoreGeometry
{
    if (LOG)
    {
        NSLog(@"%@ %@ vs %@ %@", 
              [Chip colorToString:attacker.color], [Chip chipToString:attacker.player],
              [Chip colorToString:defender.color], [Chip chipToString:defender.player]
              );
    }

    // not a legal cell 
    if (!defender) {
        return OutOfBounds;
    }
    // turn out of order
    if (attacker.color != color) {
        return NotYourTurn;
    }

    if (defender.state==FACE_DOWN) {
        return IllegalMove;
    }

    if (defender.row==attacker.row && defender.col==attacker.col){
        return SameSpot;
    }

    if (attacker.color==defender.color) {
        return IllegalMove;
    }

    // special gun rule
    if (attacker.player==Artillery && defender.player!=Empty)
    {
        if ([self specialArtilleryRule:attacker defender:defender ignoreGeometry:ignoreGeometry]) {
            return AttackerWins;
        }
    }

    // board position validation is optional for AI look-ahead like behavior
    if (!ignoreGeometry)
    {
        // too far apart
        if (abs(attacker.row-defender.row) > 1 || abs(attacker.col-defender.col) > 1) {
            return IllegalMove;
        }

        // confirm horizontal/vertical only now that we know it's no more than 1
        // position away on either axis
        if (attacker.row!=defender.row) 
        {
            if (attacker.col != defender.col){
                return IllegalMove;
            }
        }
        else if (attacker.col != defender.col) 
        {
            if (attacker.row != defender.row) {
                return IllegalMove;
            }
        }
    }

    // easy at this point
    if (defender.player==Empty){
        return EmptyTaken;
    }

    // simple rank check
    if (attacker.player==Infantry && defender.player==General){
        return AttackerWins;
    }
    if (attacker.player==General && defender.player==Infantry) {
        return DefenderWins;
    }
    if (attacker.player >= defender.player) {
        return AttackerWins;
    }

    return DefenderWins;
}
-(void)executeMove:(Chip*)attacker defender:(Chip*)defender
{
    if (defender)
    {
        [self.gameBoard moveItem:attacker to:defender];    
        [defender removeFromBoard];
    }
    // a flip
    else {
        [attacker flipChip];
    }
}
-(BOOL)isGameOver
{
    if (!self.gameBoard){
        return NO;
    }
    self.totalRed=0;
    self.totalBlue=0;
    self.redFaceDown=0;
    self.blueFaceDown=0;

    self.redGeneral = NO;
    self.blueGeneral = NO;

    for (int row=0; row < ROWS; row++)
    {
        for (int col=0; col < COLS;col++)
        {
            Chip *chip = (Chip *)[self.gameBoard getItemAt:row col:col];
            if (chip)
            {
                if (chip.player!=Empty)
                {
                    if (chip.color == RED)
                    {
                        self.totalRed++;
                        if (chip.player==General){
                            self.redGeneral=YES;
                        }
                        if (chip.state==FACE_DOWN){
                            self.redFaceDown++;
                        }
                    }
                    else if (chip.color == BLUE)
                    {
                        self.totalBlue++;
                        if (chip.player==General){
                            self.blueGeneral=YES;
                        }
                        if (chip.state==FACE_DOWN){
                            self.blueFaceDown++;
                        }
                    }
                }
            }
        }
    }

    if (self.blueFaceDown!= 0 || self.redFaceDown!=0){
        return NO;
    }
    return (self.totalRed==0 || self.totalBlue==0);
}
-(int)trim
{
    if (self.savedMoves && [self.savedMoves count] > 0)
    {
        // silly that 'remove' returns nothing
        int i = [self.savedMoves count]-1;
        GameManager *aManager = (GameManager*)[self.savedMoves objectAtIndex:i];
        [self.savedMoves removeLastObject];
        [aManager.gameBoard clear];
        return [self.savedMoves count];
    }
    return 0;
}
-(void)push
{
    BOOL virtual;

    GameManager* aClone = [[GameManager alloc] init];
    aClone.currentPlayerColor = self.currentPlayerColor;
    if ([self.gameBoard isVirtual])
    {
        virtual = YES;
        aClone.gameBoard = [self.gameBoard virtualClone];
    }
    else 
    {
        virtual = NO;
        aClone.gameBoard = [self.gameBoard clone];
    }
    aClone.totalRed = self.totalRed;
    aClone.totalBlue = self.totalBlue;
    aClone.blueGeneral = self.blueGeneral;
    aClone.redGeneral = self.redGeneral;
    aClone.blueFaceDown = self.blueFaceDown;
    aClone.redFaceDown = self.redFaceDown;
    
    if (!self.savedMoves)
    {
        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:10];
        self.savedMoves = array;
        array = nil;
    }
    [self.savedMoves insertObject:aClone atIndex:0];
    aClone=nil;

    if (LOG) {
        NSLog(@"Saved a move");
    }
    
    if ([self.savedMoves count] > MAX_UNDO)
    {
        if (virtual) {
            //NSLog(@"warning not trimming undo stack for virtual push");
        }
        else
        {
            while ([self trim] > MAX_UNDO){
            }
        }
    }
}
-(void)nextTurn
{
    if (self.currentPlayerColor==RED){
        self.currentPlayerColor=BLUE;
    }
    else {
        self.currentPlayerColor=RED;
    }
}
-(void)clearUndo
{
    if (self.savedMoves)
    {
        while ([self trim] > 0){ // everything
        }
    }
}
-(BOOL)canPop {
    return (self.savedMoves && [self.savedMoves count] > 0);
}

-(BOOL)specialArtilleryRule:(Chip*)attacker defender:(Chip*)defender 
             ignoreGeometry:(BOOL)ignoreGeometry
{
    // @todo come up with something meaningful for ignoreGeometry key since
    // we could say ignoreGeometry means allow jump diag but still N space
    // apart to assume moving to sight the enemy is path to find; then require
    // from caller the range of spaces to reach

    int chips=0;
    int blanks=0;

    Chip *middle;
    
    if (attacker.row==defender.row)
    {
        int colMin,colMax;
        
        // find at most 1 non-blank between cols
        if (attacker.col < defender.col) 
        {
            colMin = attacker.col+1;
            colMax = defender.col;
        }
        else 
        {
            colMin = defender.col+1;
            colMax = attacker.col;
        }
        if (colMin==colMax) {
            return NO;
        }
        
        for (int i = colMin; i < colMax; i++)
        {
            middle = [self.gameBoard getItemAt:attacker.row col:i];
            if (middle)
            {
                if (middle.color!=NONE){
                    chips++;
                }
                else if (middle.color==NONE){
                    blanks++;
                }
            }
        }
    }
    else if (attacker.col==defender.col)
    {
        int rowMin,rowMax;
        
        // find at most 1 non-blank between rows
        if (attacker.row < defender.row) 
        {
            rowMin = attacker.row+1;
            rowMax = defender.row;
        }
        else 
        {
            rowMin = defender.row+1;
            rowMax = attacker.row;
        }
        if (rowMin==rowMax) {
            return NO;
        }
        for (int i = rowMin; i < rowMax; i++)
        {
            middle = [self.gameBoard getItemAt:i col:attacker.col];
            if (middle)
            {
                if (middle.color!=NONE){
                    chips++;
                }
                else if (middle.color==NONE){
                    blanks++;
                }
            }
        }
    }
    return (chips==1);// || blanks > 0);
}

-(void)pop
{
    if (self.savedMoves && [self.savedMoves count] > 0)
    {
        if (LOG) {
            NSLog(@"Popping top state");
        }
        GameManager *manager = (GameManager*)[self.savedMoves objectAtIndex:0];
        [self.savedMoves removeObjectAtIndex:0];
        [self.gameBoard takeFrom:manager.gameBoard];

        // update real gamemanager with saved state
        self.currentPlayerColor = manager.currentPlayerColor;
        self.totalRed = manager.totalRed;
        self.totalBlue = manager.totalBlue;
        self.blueGeneral = manager.blueGeneral;
        self.redGeneral = manager.redGeneral;
        self.blueFaceDown = manager.blueFaceDown;
        self.redFaceDown = manager.redFaceDown;

        if (![self.gameBoard isVirtual])
        {
            for (int row=0; row < ROWS; row++)
            {
                for (int col=0; col < COLS;col++)
                {
                    Chip *chip = [self.gameBoard getItemAt:row col:col];
                    if (chip)
                    {
                        [chip addImage:self.gameBoard.origin row:row col:col 
                         size:self.gameBoard.chipSize];
                        [self.physicalBoard addSubview:chip.imageView];
                        [chip adjustNotifiers];
                    }
                }
            }
        }
        [manager.gameBoard clear];
        manager.gameBoard=nil;
        manager=nil;
    }
}
-(PlayerMove)evaluateMove:(Chip *)attacker row:(int)row col:(int)col 
{
    Chip *defender = [self getItemAt:row col:col];
    if (defender) {
        return [self evaluateMove:attacker defender:defender color:attacker.color ignoreGeometry:NO];
    }
    return IllegalMove;
}

-(BOOL)noMove:(Chip*)chip row:(int)row col:(int)col
{
    PlayerMove move = [self evaluateMove:chip row:row col:col];
    if (move==AttackerWins || move==EmptyTaken){
        return NO;
    }
    return YES;
}
// If you take an enemy piece, will you be immediately captured by another enemy piece? 
// Example your Cannon jumps & takes a Soldier, but then is captured by the enemy's Cannon;
// after attacker takes defender, does a defender player have move to take attacker?
//
// Note this returns if an attack on this attacker, post taking this defender, is 
// possible; it doesn't score it against other moves which become available
-(BOOL)isPieceDirectlyProtected:(int)row col:(int)col 
                    defenderRow:(int)defenderRow
                    defenderCol:(int)defenderCol
{
    Chip *attacker = [self getItemAt:row col:col];
    Chip *defender = [self getItemAt:defenderRow col:defenderCol];
    return [self isPieceDirectlyProtected:attacker defender:defender];
}
-(BOOL)isPieceDirectlyProtected:(Chip*)attacker defender:(Chip*)defender
{
    if (!attacker || !defender){
        return NO;
    }

    if (attacker.color == defender.color){
        return NO;
    }

    // After taking attacker, in danger?
    PlayerMove move = [self evaluateMove:attacker defender:defender color:attacker.color
                       ignoreGeometry:NO];
    if (move==AttackerWins)
    {
        // with the attacker in defender slot, then see if another 'defender' can
        // kill that newly moved 'attacker'
        int row=defender.row;
        int col=defender.col;

        for (int i = 0; i < ROWS; i++)
        {
            for (int j = 0; j < COLS; j++)
            {
                // skip new position as new attacker since it's where the attacker
                // now is as a defender
                if (i!=row && j!=col)
                {
                    Chip *chip = [self getItemAt:i col:j];
                    if (chip && chip.color == defender.color && chip.state==FACE_UP)
                    {
                        // can this chip kill attacker-as-defender?
                        move = [self evaluateMove:chip defender:attacker color:chip.color
                                ignoreGeometry:NO];
                        if (move==AttackerWins){
                            return YES;
                        }
                    }
                }
            }
        }
    }
    return NO;
}

// it cannot move because it is blocked in by upside down pieces or its teammates
-(BOOL)isPieceTrapped:(int)row col:(int)col {
    return [self isPieceTrapped:[self getItemAt:row col:col]];
}
-(BOOL)isPieceTrapped:(Chip*)chip
{
    BOOL trapped = NO;

    if (chip)
    {
        int i = chip.row;
        int j = chip.col;
        if ([self noMove:chip row:i-1 col:j]){
            if ([self noMove:chip row:i+1 col:j]) {
                if ([self noMove:chip row:i col:j-1]) {
                    if ([self noMove:chip row:i col:j+1]){
                        trapped = YES;
                    }
                }
            }
        }

        if (trapped && chip.player==Artillery) 
        {
            for (int k = 1; k <= COLS; k++)
            {
                if ([self noMove:chip row:i-k col:j]){
                    if ([self noMove:chip row:i+k col:j]){
                        if ([self noMove:chip row:k col:j-k]) {
                            if ([self noMove:chip row:k col:j+k]){
                                trapped = YES;
                            }
                        }
                    }
                }
                else 
                {
                    trapped = NO;
                    break;
                }
            }
        }
    }
    return trapped;
}

-(void)prepareVirtualBoard
{
    if ([self.gameBoard isVirtual]){
        NSLog(@"error, virtual board active!");
    }
    else
    {
        GameBoard *clone = [self.gameBoard virtualClone];
        self.realBoard = self.gameBoard;
        self.gameBoard = clone;
        clone = nil;
    }
}
-(void)restoreRealBoard
{
    if (!self.realBoard) {
        NSLog(@"No board to restore!");
    }
    else
    {
        self.gameBoard = self.realBoard;
        self.realBoard=nil;
    }
}

-(void)peekBoard
{    
    NSMutableArray *temp = [[NSMutableArray alloc]init];

    for (int i = 0; i < ROWS; i++)
    {
        for (int j = 0; j < COLS; j++)
        {
            Chip *chip = [self getItemAt:i col:j];
            if (chip.state==FACE_DOWN)
            {
                UIImage *newImage = [UIImage imageNamed:[chip imageNameForChip]];
                UIImageView *view = [[UIImageView alloc] initWithImage:newImage];
                view.alpha=0;
                view.frame = chip.imageView.frame;
                [temp addObject:view];
                [chip.imageView.superview addSubview:view];

                view.userInteractionEnabled = NO;
            }
            chip.imageView.userInteractionEnabled = NO;
        }
    }

    [UIView animateWithDuration:REVEAL_DURATION
     delay:0
     options:UIViewAnimationOptionTransitionNone
     animations:^{
            for (UIImageView *view in temp) {
                view.alpha=1;
            }
        }
      completion:^(BOOL finished) {
            [UIView animateWithDuration:REVEAL_UNDO_DURATION
             delay:REVEAL_UNDO_DELAY
             options:UIViewAnimationOptionTransitionNone
             animations:^{
                    for (UIImageView *view in temp) {
                        view.alpha=0;
                    }
                }
              completion:^(BOOL finished) {
                    for (UIImageView *view in temp) {
                        [view removeFromSuperview];
                    }
                    for (int i = 0; i < ROWS; i++)
                    {
                        for (int j = 0; j < COLS; j++)
                        {
                            Chip *chip = [self getItemAt:i col:j];
                            chip.imageView.userInteractionEnabled = YES;
                        }
                    }
                }
             ];
        }
     ];

    temp=nil;
}


-(void)dealloc
{
    [self clearUndo];
    self.realBoard=nil;
    self.savedMoves=nil;
    self.gameBoard=nil;
}
@end


