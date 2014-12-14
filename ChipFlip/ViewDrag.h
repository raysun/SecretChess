//
//  ViewDrag.h
//  ChipFlip
//
//  Created by julie m on 6/9/13.
//  Copyright (c) 2013 just4fun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum dragFrom
{
    LEFT,
    RIGHT,
    UP,
    DOWN,
} DragFrom;

@interface ViewDrag : NSObject
{
    UIView *_inView;
    CGRect _inFrame;
    UIImageView *_dragView;
    NSString *_filename;
    DragFrom _direction;
    CGPoint _dragCenter;
    CGPoint _origin;
    float _margin;       // from edge,drag must be <= margin
    BOOL _active;
}
@property (retain) UIView *inView;
@property (retain) UIImageView *dragView;
@property (retain) NSString *filename;
@property CGRect inFrame;
@property DragFrom direction;
@property CGPoint dragCenter;
@property CGPoint origin;
@property float margin;
@property BOOL active;

-(id)initWithFilename:(NSString*)filename inView:(UIView*)inView inFrame:(CGRect)inFrame
            direction:(DragFrom)direction margin:(float)margin;
-(void)move:(UIPanGestureRecognizer *)recognizer;
-(void)completeDrag;
-(void)reverseDrag;
@end
