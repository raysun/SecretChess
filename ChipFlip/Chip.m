//
//  Chip.m
//  ChipFlip
//
//  Created by Secret Chess on 6/1/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import "Constants.h"
#import "Chip.h"
#import "GameBoard.h"
#import "Blah.h"

#define INSET_FRAME(f){f.size.width -= CELL_INSET; f.origin.x += CELL_INSET/2;\
        f.size.height -= CELL_INSET; f.origin.y += CELL_INSET/2;}

@interface Chip()
{
    BOOL _virtual;  // shortcut
}
@property BOOL virtual;
@end


@implementation Chip

static NSString *lock = @"lock";
static int movingIdent=-1;

-(id)initWithPlayer:(Player)player color:(PlayerColor)color
{
    if (self = [super init])
    {
        self.state = (player==Empty ? FACE_UP : FACE_DOWN);
        self.color = color;
        self.player = player;
        self.ident = [GameBoard safeIdent];
        if (self.player==Empty){
            self.ident = 1 - self.ident;
        }
        self.virtual=NO;
    }
    return self;
}
// serializers
- (id)initWithCoder:(NSCoder *)decoder 
{
    if (self = [super init]) 
    {
        self.player = [decoder decodeIntForKey:@"player"];
        self.color = [decoder decodeIntForKey:@"color"];
        self.state = [decoder decodeIntForKey:@"state"];       
        self.cellBounds = [[decoder decodeObjectForKey:@"bounds"] CGRectValue];
        self.ident = [GameBoard safeIdent];//[decoder decodeInt32ForKey:@"ident"];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)encoder 
{
    [encoder encodeInt:self.player forKey:@"player"];
    [encoder encodeInt:self.color forKey:@"color"];
    [encoder encodeInt:self.state forKey:@"state"];
    [encoder encodeObject:[NSValue valueWithCGRect:self.cellBounds] forKey:@"bounds"];
    [encoder encodeInt32:self.ident forKey:@"ident"];
    // owner has to build images, etc - which builds recognizers, etc
}
-(NSString*)niceName
{
    return [NSString stringWithFormat:@"%@%@", 
            [Chip colorToString:self.color], [Chip chipToString:self.player]];
}
-(NSString*)fullName {
    return [NSString stringWithFormat:@"%@(%d,%d)", [self niceName], self.row, self.col];
}

// for drag to look right images must be topmost
-(void)moveOnTop 
{
    if (self.imageView && self.imageView.superview){
        [self.imageView.superview addSubview:self.imageView];
    }
}

-(void)removeFromBoard 
{
    if (self.imageView)
    {
        if ([self isVirtual]){
            NSLog(@"why do i have an image if virtual?");
        }
        [self.imageView removeFromSuperview];
        self.imageView = nil;
    }
}
-(void)fixViewRect
{
    CGRect frame = self.cellBounds;
    INSET_FRAME(frame);
    self.imageView.frame = frame;
}

+(NSString*)indicatorImage:(PlayerColor)color {
    return [NSString stringWithFormat:@"%@.png", [Chip colorToString:color]];
}
-(void)adjustNotifiers
{
    // remove tap once facing up
    if (self.state == FACE_UP)
    {
        if (self.imageView && self.tap) 
        {
            [self.imageView removeGestureRecognizer:self.tap];
            self.tap = nil;
        }

        // and add pan for dragging 
        if (!self.pan)
        {
            UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] 
                                                     initWithTarget:self action:@selector(move:)];
            [panRecognizer setMinimumNumberOfTouches:1];
            [panRecognizer setMaximumNumberOfTouches:1];
            //[panRecognizer setDelegate:self];
            [self.imageView addGestureRecognizer:panRecognizer];
            self.pan = panRecognizer;
            panRecognizer = nil;
        }
    }
    else
    {
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] 
                                                        initWithTarget:self 
                                                        action:@selector(tapOn:)];
        [self.imageView addGestureRecognizer:tapGestureRecognizer];    
        self.tap = tapGestureRecognizer;
        tapGestureRecognizer = nil;
    }
}
// rude to do ui in this file but it's basically all over
-(void)flipChip
{
    self.state = FACE_UP;
    if ([self isVirtual]) {
        return;
    }

    UIImage *newImage = [UIImage imageNamed:[self imageNameForChip]];
    self.imageView.transform = CGAffineTransformMakeScale(.1, .1);
    
    [self adjustNotifiers];
    
    [UIView transitionWithView:self.imageView
     duration:CHIP_FLIP_SPEED
     options:UIViewAnimationOptionTransitionCrossDissolve
     animations:^{
            self.imageView.image = newImage;
            self.imageView.transform = CGAffineTransformMakeScale(1, 1);
        } 
      completion:^(BOOL finished) {
        }
     ];
}
// blueArtillery
// 0123456890123
-(NSString *)description
{
    if (self.player==Empty){
        return @"XX";
    }

    NSString *p = @"?";
    NSString *c = ([self isRed] ? @"r" : @"b");    

    if (self.state==FACE_UP)
    {
        switch (self.player)
        {
         case General:
             p = @"G";
             break;
         case Advisor:
             p = @"A";
             break;
         case Elephant:
             p = @"E";
             break;
         case Chariot:
             p = @"C";
             break;
         case Horse:
             p = @"H";
             break;
         case Artillery:
             p = @"S";    // soilder
             break;
         case Infantry:
             p = @"I";
             break;
         default:
             p = @"!";
             break;
        }
        return [NSString stringWithFormat:@"%@%@", c,p];
    }
    else {
        return @"??";
    }

}

-(void)tapOn:(UIGestureRecognizer *)recognizer
{
#if LOG
    NSLog(@"tap...%@", [chip niceName]);
#endif
    if (self.state!=FACE_UP)
    {
        movingIdent=self.ident;

        // notify so parent flips
        [[NSNotificationCenter defaultCenter] 
         postNotification:[NSNotification notificationWithName:CHIP_FLIPPED object:nil]];
    }
}
-(void)move:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state==UIGestureRecognizerStateEnded) 
    {
        @synchronized (lock) {
            if (movingIdent != self.ident) {
                return;
            }
        }
        [[NSNotificationCenter defaultCenter] 
         postNotification:[NSNotification notificationWithName:CHIP_DRAG_STOP object:nil]];
    }
    else if (recognizer.state== UIGestureRecognizerStateCancelled)
    {
        @synchronized (lock) {
            if (movingIdent != self.ident) {
                return;
            }
        }

#if LOG
        NSLog(@"cancel move...%@",  [chip niceName]); 
#endif

        [[NSNotificationCenter defaultCenter] 
         postNotification:[NSNotification notificationWithName:CHIP_DRAG_CANCEL object:nil]];

        // back home
        CGRect frame = self.cellBounds;
        INSET_FRAME(frame);
        self.imageView.frame = frame;
    }
    else if (UIGestureRecognizerStateBegan==recognizer.state)
    {
        @synchronized (lock) {
            if (movingIdent !=-1 && movingIdent != self.ident) {
                return;
            }
            movingIdent = self.ident;
        }

        // To make things look right, the image of this chip should be topmost
        // else it appears to drag under chips placed on the board after it; this
        // causes a reordering
        [self moveOnTop];

        [[NSNotificationCenter defaultCenter] 
         postNotification:[NSNotification notificationWithName:CHIP_DRAG_START object:nil]];
    }

    // drag the chip but it's final home comes later
    else if (UIGestureRecognizerStateChanged==recognizer.state) 
    {
        @synchronized (lock) {
            if (movingIdent != self.ident) {
                return;
            }
        }
        self.imageView.center = [recognizer locationInView:self.imageView.superview];
        [[NSNotificationCenter defaultCenter] 
         postNotification:[NSNotification notificationWithName:CHIP_DRAG_MOVE object:nil]];
    }
}

-(BOOL)isRed {
    return self.color==RED;
}

-(BOOL)isBlue{
    return self.color==BLUE;
}
-(BOOL)isVirtual{
    return self.virtual;
}

-(Chip*)clone:(BOOL)virtual
{
    Chip* aClone = [[Chip alloc] initWithPlayer:self.player color:self.color];
    aClone.state = self.state;
    aClone.row = self.row;
    aClone.col = self.col;
    aClone.cellBounds = self.cellBounds;
    aClone.ident = self.ident;
    aClone.virtual=virtual;

    //NSLog(@"cloned a chip, virtual: %@", (virtual ? @"Yes":@"No"));

    return aClone;
}
+(long)activeChip {
    return movingIdent;
}
+(void)clear{
    movingIdent = -1;
}
+(Chip*)emptyChip:(BOOL)virtual
{
    Chip *c = [[Chip alloc] initWithPlayer:Empty color:NONE];
    c.virtual = virtual;

    if (!virtual){
        // require empty image for later use
        [c addImage:CGPointZero row:0 col:0 size:CGSizeZero];
    }
    return c;
}
+(int)countByType:(Player)player
{
    switch (player)
    {
     case Empty:
         return 0;
     case General:
         return 1;
     case Advisor:
     case Elephant:
     case Chariot:
     case Horse:
     case Artillery:
         return 2;
     case Infantry:
         return 5;
    }
    return 0;
}
+(NSString*)colorToString:(PlayerColor)color 
{
    if (color==RED){
        return RED_PREFIX;
    }
    if (color==BLUE){
        return BLUE_PREFIX;
    }
    if (color==NONE){
        return @"empty";
    }
    return @"unknown";
}
+(NSString*)chipToString:(Player)player
{
    switch (player)
    {
     case General:
         return @"General";
     case Advisor:
         return @"Advisor";
     case Elephant:
         return @"Elephant";
     case Chariot:
         return @"Chariot";
     case Horse:
         return @"Horse";
     case Artillery:
         return @"Artillery";
     case Infantry:
         return @"Infantry";
     case Empty:
         return @"Empty";
     default:
         return @"unknown";
    }
}

-(NSString*)imageNameForChip
{
    if (self.player==Empty){
        return @"Transparent.png";
    }
    return [NSString stringWithFormat:@"%@%@.png", 
            [Chip colorToString:self.color], [Chip chipToString:self.player]];
}
-(void)hideChip:(BOOL)hide
{
    if (self.imageView){
        self.imageView.hidden=hide;
    }
}

// add image and set bounds; even empty cells have bounds
-(void)addImage:(CGPoint)topleft row:(int)row col:(int)col size:(CGSize)size
{
    if (self.virtual)
    {
      NSLog(@" addImage on virtual cell!");
      return;
    }

    UIImageView *view = nil;

    // figure the cell the image must fit into
    float x = topleft.x + (col * size.width);
    float y = topleft.y + row * size.height;

    NSString *name;
    if (self.player!=Empty) {
        name = (self.state==FACE_UP ? [self imageNameForChip] : FACE_DOWN_IMAGE);
    }
    else {
        name = BLANK_CHIP;
    }
    view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:name]];
    
    CGRect frame = CGRectMake(x, y, size.width, size.height);    
    self.cellBounds = frame; 

    if (view)
    {
        // force the image to fit w/o banging into the grid
        INSET_FRAME(frame);
        view.frame = frame;
        self.imageView = view;
        self.imageView.userInteractionEnabled = YES;
        view = nil;
    }
    else {
        NSLog(@"chip w/o view!");
    }
}
-(void)dealloc 
{
    [Blah nukeGestures:self.imageView];
    [self removeFromBoard];
}
@end
