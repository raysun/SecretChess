//
//  Created by Secret Chess on 6/1/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import "GameBoard.h"
#import "Constants.h"

static int ident=1;

@interface GameBoard ()
{
    NSMutableArray * _data;
    int _rows, _cols;
    BOOL _virtual;           // shortcut
}
@property (retain) NSMutableArray *data;
@property int rows;
@property int cols;
@property BOOL virtual;

-(GameBoard*)doClone:(BOOL)virtual;

@end

@interface GameBoard ()
-(void)privateShowHide:(BOOL)show;
-(id)initWithRows:(int)rows cols:(int)cols size:(CGSize)size origin:(CGPoint)origin 
               virtual:(BOOL)virtual;
@end

@implementation GameBoard


+(GameBoard*)buildBoard:(CGSize)size origin:(CGPoint)origin {
    return [[GameBoard alloc] initWithRows:ROWS cols:COLS size:size origin:origin virtual:NO];
}

-(id)initWithRows:(int)rows cols:(int)cols size:(CGSize)size origin:(CGPoint)origin
          virtual:(BOOL)virtual
{
    if (self = [super init])
    {
        self.cols = cols;
        self.rows = rows;
        self.chipSize = size;
        self.origin = origin;

        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:rows];
        self.data = array;

        for (int i = 0; i < rows; i++)
        {
            NSMutableArray *row = [[NSMutableArray alloc] initWithCapacity:cols];
            for (int j = 0; j < cols; j++){
                [row addObject:[Chip emptyChip:virtual]];
            }
            [array addObject:row];
            row = nil;
        }

        self.data = array;
        array = nil;

        ident = 1; //reset

        self.virtual = NO;

        [self syncBoardCells];
    }
    return self;
}
-(void)takeFrom:(GameBoard*)board
{
    [self clear];
    self.data = board.data;
    board.data = nil;
    [self syncBoardCells];
}
-(BOOL)isVirtual{
    return self.virtual;
}
-(GameBoard*)virtualClone {
    return [self doClone:YES];
}

-(GameBoard*)clone {
    return [self doClone:NO];
}
-(GameBoard*)doClone:(BOOL)virtual
{
    GameBoard *aClone = [[GameBoard alloc] initWithRows:self.rows cols:self.cols 
                         size:self.chipSize origin:self.origin virtual:virtual];
    aClone.virtual = virtual;

    for (int i=0;i<ROWS;i++)
    {
        for (int j=0; j<COLS;j++)
        {
            Chip *item = [self getItemAt:i col:j];
            // these assignments shouldn't be needed
            item.row=i;
            item.col=j;
            // shallow, no images or gesture handlers
            [aClone putItemAt:[item clone:virtual] row:i col:j];
        }
    }
    return aClone;
}
+(int)safeIdent {
    return ident++;
}
// does update the chip row/col
-(void)moveItem:(Chip*)chip to:(Chip*)to
{
    BOOL virtual = [self isVirtual];

    Chip *emptyChip = [Chip emptyChip:virtual];
    emptyChip.cellBounds = chip.cellBounds;
    [emptyChip fixViewRect];

    if (!virtual)
    {
#if defined(DEBUG_BLANK_CHIP)
        [chip.imageView.superview addSubview:emptyChip.imageView];
#endif
    }

    [self replaceItem:chip with:emptyChip];

    emptyChip=nil;
    chip.cellBounds = to.cellBounds;

    if (to.imageView && !virtual) {
        chip.imageView.frame = to.imageView.frame;
    }

    [self replaceItem:to with:chip];
    [self syncBoardCells];
}

// brute force - does NOT update the chip row/col!
-(void)replaceItem:(Chip*)oldItem with:(Chip*)newItem
{
    NSMutableArray *aRow = (NSMutableArray *)[self.data objectAtIndex:oldItem.row];
    [aRow replaceObjectAtIndex:oldItem.col withObject:newItem];
}

-(void)syncBoardCells 
{
    for (int i=0;i<ROWS;i++)
    {
        for (int j=0; j<COLS;j++)
        {
            Chip *item = [self getItemAt:i col:j];
            item.row=i;
            item.col=j;
        }
    }
}

// do something stupid, crash
-(void)putItemAt:(Chip *)item row:(int)row col:(int)col 
{
    NSMutableArray *aRow = (NSMutableArray *)[self.data objectAtIndex:row];
    [aRow replaceObjectAtIndex:col withObject:item];
}

-(Chip *)getItemAt:(int)row col:(int)col 
{
    if (row < 0 || row >= ROWS || col < 0 || col >= COLS){
        return nil;
    }
    return [(NSArray *)[self.data objectAtIndex:row] objectAtIndex:col];
}

-(CGPoint)locationFromChip:(Chip*)chip;
{
    for (int i = 0; i < self.rows; i++) 
    {
        for (int j = 0; j < self.cols; j++) 
        {
            Chip *item = [self getItemAt:i col:j];
            if (item.ident == chip.ident) {
                return CGPointMake(i, j);
            }
        }
    }
    return CGPointMake(-1,-1);
}

// using cell size, find out what rect this intersects and return the item
-(Chip *)getItemByPt:(CGPoint)pt 
{
    //normalize as if grid at 0,0 and find hit
    int row = (pt.y-self.origin.y)/self.chipSize.height;
    int col = (pt.x-self.origin.x)/self.chipSize.width;

    if (row < 0 || row >= self.rows){
        return nil;
    }
    if (col < 0 || col >= self.cols){
        return nil;
    }

    return [self getItemAt:row col:col];
}
-(Chip *)getItemByIdent:(int)ident
{
    if (ident != -1)
    {
        if (self.data)
        {
            for (int row=0; row < self.rows; row++)
            {
                for (int col=0; col < self.cols;col++)
                {
                    Chip *chip = (Chip *)[self getItemAt:row col:col];
                    if (chip && chip.ident==ident){
                        return chip;
                    }
                }
            }
        }
    }
    return nil;
}

// 1 chip's bounds in a list
-(NSArray *)getChipOutline:(Chip*)chip {
    return [NSArray arrayWithObject:[NSValue valueWithCGRect:chip.cellBounds]];
}
-(NSArray *)getChipOutlines
{    
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:self.rows*self.cols];
    if (self.data)
    {
        for (int row=0; row < self.rows; row++)
        {
            for (int col=0; col < self.cols;col++)
            {
                Chip *chip = (Chip *)[self getItemAt:row col:col];
                [array addObject:[NSValue valueWithCGRect:chip.cellBounds]];
            }
        }
    }
    return (NSArray*)array;
}

-(void)privateShowHide:(BOOL)hide
{
    if (self.data)
    {
        for (int i = 0; i < self.rows; i++) 
        {
            for (int j = 0; j < self.cols; j++) 
            {
                Chip *item = [self getItemAt:i col:j];
                if (item) {
                    [item hideChip:hide];
                }
            }
        }
    }
}
-(void)hide {
    [self privateShowHide:YES];
}
-(void)unHide {
    [self privateShowHide:NO];
}

-(void)clear
{
    if (self.data)
    {
        for (int i = 0; i < self.rows; i++) 
        {
            for (int j = 0; j < self.cols; j++) 
            {
                Chip *item = [self getItemAt:i col:j];
                if (item) {
                    [item removeFromBoard];
                }
            }
        }

        for (int row=self.rows-1; row > -1; row--)
        {
            NSMutableArray *aRow = (NSMutableArray *)[self.data objectAtIndex:row];
            for (int col=0; col < self.cols;col++) {
                [aRow removeLastObject];
            }
            [self.data removeLastObject];
        }

        self.data = nil;
    }
}

// don't forget to call clear before this
-(void) dealloc {
    [self clear];
}
@end

