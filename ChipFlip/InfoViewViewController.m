//
//  InfoViewViewController.m
//  ChipFlip
//
//  Created by Secret Chess on 6/11/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import "InfoViewViewController.h"
#import "Constants.h"
#import "Blah.h"

@interface InfoViewViewController ()

@end

@implementation InfoViewViewController

// thanks stackoverflow.com
-(void)hideUghlyGradientCrap:(UIView*)theView
{
    if (theView && theView.subviews)
    {
        for (UIView* subview in theView.subviews)
        {
            if ([subview isKindOfClass:[UIImageView class]]) {
                subview.hidden = YES;
            }
            [self hideUghlyGradientCrap:subview];
        }    
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        // Custom initialization
        CGRect frame;
        frame = self.view.frame;
        self.webview.frame = frame;

        // now fix the button
        frame = self.closebtn.frame;
        frame.origin.x = [[UIScreen mainScreen] bounds].size.height - 
            (self.closebtn.frame.size.width);
        self.closebtn.frame = frame;

        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] 
                                                        initWithTarget:self 
                                                        action:@selector(closeView)];
        [self.closebtn addGestureRecognizer:tapGestureRecognizer];
        tapGestureRecognizer = nil;

        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                           action:@selector(closeView)];
        swipe.direction=UISwipeGestureRecognizerDirectionDown;
        [self.closebtn addGestureRecognizer:swipe];
        self.closebtn.userInteractionEnabled = YES;
        swipe = nil;

        NSString *imagePath = [[NSBundle mainBundle] resourcePath];
        imagePath = [imagePath stringByReplacingOccurrencesOfString:@"/" withString:@"//"];
        imagePath = [imagePath stringByReplacingOccurrencesOfString:@" " withString:@"%20"];

        NSString *root = [[NSBundle mainBundle] resourcePath];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", root, @"index.html"];
        NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:filePath]];
        NSString *temp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        NSString* compileDateString = [NSString stringWithFormat:@"%@ %@",
                                       [NSString stringWithUTF8String:__DATE__],
                                       [NSString stringWithUTF8String:__TIME__]];
        
        NSString *html = [temp stringByReplacingOccurrencesOfString:@"$$build$$" 
                          withString:compileDateString];
        temp=nil;
        
        [self.webview loadHTMLString:html baseURL:[NSURL URLWithString: 
                                                   [NSString stringWithFormat:@"file:/%@/", 
                                                    imagePath]]];
        [self hideUghlyGradientCrap:self.webview];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)closeView 
{
    [self.webview stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML = \"\";"];
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)dealloc {
    [Blah nukeGestures:self.closebtn];
}
@end
