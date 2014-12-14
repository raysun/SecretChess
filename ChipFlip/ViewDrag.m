//
//  ViewDrag.m
//  ChipFlip
//
//  Created by julie m on 6/9/13.
//  Copyright (c) 2013 just4fun. All rights reserved.
//
#import "Constants.h"
#import "ViewDrag.h"

@interface ViewDrag ()
@end

@implementation ViewDrag

-(id)initWithFilename:(NSString*)filename inView:(UIView*)inView inFrame:(CGRect)inFrame
            direction:(DragFrom)direction margin:(float)margin
{
    if (self = [super init]) 
    {
        self.inView = inView;
        self.inFrame = inFrame;
        self.filename = filename;
        self.direction = direction;
        self.margin = margin;
    }
    return self;
}
-(void)completeDrag
{
    if (self.dragView)
    {
        [UIView transitionWithView:self.dragView
         duration:VIEW_DROP_DOWN_TIME
         options:UIViewAnimationOptionBeginFromCurrentState
         animations:^{
                CGRect frame = self.dragView.frame;
                switch(self.direction)
                {
                 case LEFT:
                 case RIGHT:
                     frame.origin.x = 0;
                     break;
                 case UP:
                 case DOWN:
                     frame.origin.y = 0;
                     break;
                }
                self.dragView.frame=frame;
            } 
          completion:^(BOOL finished) {
                [self.dragView removeFromSuperview];
                self.dragView=nil;

                // to let the animation complete w/o conflict, tell parent when done
                [[NSNotificationCenter defaultCenter] 
                 postNotification:[NSNotification notificationWithName:VIEW_DRAG_DONE object:nil]];
            }
         ];
    }
}
-(void)reverseDrag
{
    if (self.dragView)
    {
        [UIView transitionWithView:self.dragView
         duration:VIEW_SLIDE_BACK_TIME
         options:UIViewAnimationOptionBeginFromCurrentState
         animations:^{
                CGRect frame = self.dragView.frame;
                frame.origin = self.origin;
                self.dragView.frame=frame;
            } 
          completion:^(BOOL finished) {
                [self.dragView removeFromSuperview];
                self.dragView=nil;
            }
         ];
    }
}

-(void)move:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state==UIGestureRecognizerStateEnded) 
    {
        if (!self.active){
            return;
        }

        [[NSNotificationCenter defaultCenter] 
         postNotification:[NSNotification notificationWithName:VIEW_DRAG_STOP object:nil]];
    }
    else if (recognizer.state== UIGestureRecognizerStateCancelled)
    {
        if (!self.active){
            return;
        }

        [[NSNotificationCenter defaultCenter] 
         postNotification:[NSNotification notificationWithName:VIEW_DRAG_CANCEL object:nil]];
    }
    else if (UIGestureRecognizerStateBegan==recognizer.state)
    {
        self.active = NO;

        CGPoint newPt = [recognizer locationInView:self.inView];
        switch(self.direction)
        {
         case LEFT:
             if (newPt.x - self.margin > 0){
                 return;
             }
             break;
         case RIGHT:
             if (newPt.x  < self.inView.frame.size.width-self.margin){
                 return;
             }
             break;
         case UP:
             if (newPt.y  - self.margin > 0){
                 return;
             }
             break;
         case DOWN:
             if (newPt.y  < self.inView.frame.size.height-self.margin){
                 return;
             }
             break;
        }

        self.active = YES;

        NSData *data = [[NSFileManager defaultManager] contentsAtPath:self.filename];
        UIImageView *drag =  [[UIImageView alloc] initWithImage:[UIImage imageWithData:data]];

        // note that our image may be @2x
        CGSize viewSize = self.inFrame.size;
        CGSize size = drag.frame.size;

        double ratio = viewSize.width/size.width;
        size.width *= ratio;
        size.height *= ratio;

        // by direction, push new view offscreen
        switch(self.direction)
        {
         case LEFT:
             self.origin = CGPointMake(-size.width, 0);
             break;
         case RIGHT:
             self.origin = CGPointMake(size.width, 0);
             break;
         case UP:
             self.origin = CGPointMake(0, -size.height);
             break;
         case DOWN:
             self.origin = CGPointMake(0, size.height);
             break;
        }
        drag.frame = CGRectMake(self.origin.x, self.origin.y, size.width, size.height);

        [self.inView addSubview:drag];
        self.dragView=drag;
        drag=nil;

        [[NSNotificationCenter defaultCenter] 
         postNotification:[NSNotification notificationWithName:VIEW_DRAG_START object:nil]];
    }

    else if (UIGestureRecognizerStateChanged==recognizer.state) 
    {
        if (!self.active){
            return;
        }

        CGPoint newPt = [recognizer locationInView:self.inView];
        CGPoint center = self.dragView.center;
        CGSize size = self.dragView.frame.size;

        // based on direction, limit the dragged image movement
        switch(self.direction)
        {
         case LEFT:
             newPt.x -= size.width/2;
             newPt.y = center.y;
             break;
         case RIGHT:
             newPt.x += size.width/2;
             newPt.y = center.y;
             break;
         case UP:
             newPt.y -= size.width/2;
             newPt.x = center.x;
             break;
         case DOWN:
             newPt.y += size.width/2;
             newPt.x = center.x;
             break;
        }

        self.dragCenter = newPt;
        self.dragView.center = newPt;
        [[NSNotificationCenter defaultCenter] 
         postNotification:[NSNotification notificationWithName:VIEW_DRAG_MOVE object:nil]];
    }
}

-(void)dealloc {
    self.inView=nil;
}

@end
