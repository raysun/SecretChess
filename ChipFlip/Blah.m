#import "Blah.h"


@implementation Blah
+(void)nukeGestures:(UIView*)v
{
    if (v)
    {
        for (UIGestureRecognizer *recognizer in v.gestureRecognizers) {
            [v removeGestureRecognizer:recognizer];
        }
    }
}
@end
