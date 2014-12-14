//
//
//  Created by Secret Chess on 2/21/11.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "LoadingView.h"


@implementation LoadingViewJ


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.delegate) {
        [self.delegate touched];
    }
}

+ (id)loadingViewInViewWithBounds:(UIView *)aSuperview 
                          bounds:(CGRect)bounds 
{
	LoadingViewJ *loadingView = [[LoadingViewJ alloc] initWithFrame:bounds];

	if (!loadingView) {
		return nil;
	}

    [loadingView setBackgroundColor:[UIColor clearColor]];
	[aSuperview addSubview:loadingView];

	UIActivityIndicatorView *activityIndicatorView =
		[[UIActivityIndicatorView alloc]
         initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[loadingView addSubview:activityIndicatorView];
	activityIndicatorView.autoresizingMask =
		UIViewAutoresizingFlexibleLeftMargin |
		UIViewAutoresizingFlexibleRightMargin |
		UIViewAutoresizingFlexibleTopMargin |
		UIViewAutoresizingFlexibleBottomMargin;

    CGRect activityIndicatorRect = activityIndicatorView.frame;
    activityIndicatorRect.size.width=40;
    activityIndicatorRect.size.height=40;
    activityIndicatorRect.origin.x = loadingView.frame.size.width/2 
        - activityIndicatorRect.size.width/2;
    activityIndicatorRect.origin.y = loadingView.frame.size.height/2;
    activityIndicatorView.frame = activityIndicatorRect;

    activityIndicatorView.layer.cornerRadius = 5;
    activityIndicatorView.layer.masksToBounds = YES;

    [activityIndicatorView setBackgroundColor:[UIColor grayColor]];
	[activityIndicatorView startAnimating];
    activityIndicatorView=nil;

	return loadingView;
}

//
// removeView
//
// Animates the view out from the superview. As the view is removed from the
// superview, it will be released.
//
- (void)removeView
{
	UIView *aSuperview = [self superview];
	[super removeFromSuperview];

	// Set up the animation
	CATransition *animation = [CATransition animation];
	[animation setType:kCATransitionFade];
	
	[[aSuperview layer] addAnimation:animation forKey:@"layerAnimation"];
}

//
// dealloc
//
// Release instance memory.
//
- (void)dealloc
{
    self.delegate=nil;
}

@end
