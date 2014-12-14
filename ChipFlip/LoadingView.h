
#import <UIKit/UIKit.h>

@protocol LoadingViewViewDelegateJ;

@interface LoadingViewJ : UIView
{
	IBOutlet id<LoadingViewViewDelegateJ> _delegate;
}
@property (retain) id<LoadingViewViewDelegateJ> delegate;

+ (id)loadingViewInViewWithBounds:(UIView *)aSuperview 
                   bounds:(CGRect)bounds;
- (void)removeView;

@end

@protocol LoadingViewViewDelegateJ
-(void)touched;
@end

