//
//  InfoViewViewController.h
//  ChipFlip
//
//  Created by Secret Chess on 6/11/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfoViewViewController : UIViewController
{
    IBOutlet UIWebView *_webview;
    IBOutlet UIImageView *_closebtn;
}
@property UIWebView *webview;
@property UIImageView *closebtn;

-(void)closeView;
@end
