//
//  Chip.h
//  ChipFlip
//
//  Created by Secret Chess on 6/1/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Player.h"

@interface Chip : NSObject <NSCoding>
{
    Player _player;
    PlayerColor _color;
    PlayerState _state;    
    int _row;
    int _col;

    CGRect _cellBounds;
    int _ident;
    UIImageView *_imageView;
    UITapGestureRecognizer* _tap;
    UIPanGestureRecognizer *_pan;
}
@property PlayerColor color;
@property Player player;
@property PlayerState state;
@property CGRect cellBounds;
@property int ident;
@property int row;
@property int col;

@property (retain) UIImageView *imageView;
@property (retain) UITapGestureRecognizer* tap;
@property (retain) UIPanGestureRecognizer *pan;

-(id)initWithPlayer:(Player)player color:(PlayerColor)color;

-(BOOL)isRed;
-(BOOL)isBlue;
-(NSString*)imageNameForChip;

-(void)addImage:(CGPoint)topleft row:(int)row col:(int)col size:(CGSize)size;
-(void)adjustNotifiers;
-(void)removeFromBoard;
-(void)hideChip:(BOOL)hide;
-(void)flipChip;
-(void)moveOnTop;
-(void)fixViewRect;

+(NSString*)colorToString:(PlayerColor)color;
+(NSString*)chipToString:(Player)player;
+(int)countByType:(Player)player;
+(NSString*)indicatorImage:(PlayerColor)color;

-(NSString*)niceName;
-(NSString*)fullName;

+(long)activeChip;
+(void)clear;
+(Chip*)emptyChip:(BOOL)virtual;

-(Chip*)clone:(BOOL)virtual;
-(BOOL)isVirtual;
@end
