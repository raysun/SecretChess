//
//  Created by Secret Chess on 6/1/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//
#import "Chip.h"
#import "Player.h"

@interface GameBoard : NSObject
{
    CGSize _chipSize;
    CGPoint _origin;
}
@property CGSize chipSize;
@property CGPoint origin;

// chips keep row/col indexes for the AI to use so need to be updated after
// larger moves 
-(void)syncBoardCells;

-(void)putItemAt:(Chip *)item row:(int)row col:(int)col;
-(Chip *)getItemAt:(int)row col:(int)col;
-(Chip *)getItemByPt:(CGPoint)pt;
-(Chip *)getItemByIdent:(int)ident;

-(void)replaceItem:(Chip*)oldItem with:(Chip*)newItem;
-(void)moveItem:(Chip*)chip to:(Chip*)to;
-(CGPoint )locationFromChip:(Chip*)chip;

-(NSArray *)getChipOutlines;
-(NSArray *)getChipOutline:(Chip*)chip; // 1 chip's bounds in a list

-(void)clear;
-(void)hide;
-(void)unHide;

+(GameBoard*)buildBoard:(CGSize)size origin:(CGPoint)origin;
+(int)safeIdent;

-(GameBoard*)clone;
-(GameBoard*)virtualClone;
-(BOOL)isVirtual;
-(void)takeFrom:(GameBoard*)board;
@end
