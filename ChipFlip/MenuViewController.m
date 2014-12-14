//
//  MenuViewController.m
//  SecretChess
//
//  Created by Secret Chess on 6/24/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import "MenuViewController.h"
#import "Blah.h"

@interface MenuViewController ()
-(void)closeView;
@end

@implementation MenuViewController

-(void)updateMusicButtons
{
    if (self.musicIsOn){
        self.musicBtn.image = [UIImage imageNamed:@"musicOn.png"];
    }
    else {
        self.musicBtn.image = [UIImage imageNamed:@"musicOff.png"];
    }
}

-(void)addToWithEffect:(UIView*)parent
{
    [parent addSubview:self.view];

    CGRect frame = self.view.frame;
    frame.origin.x = frame.size.width;
    frame.origin.y = frame.size.height;

    self.view.frame = frame;
            
    [UIView animateWithDuration:MENU_SLIDE_DURATION
     delay:0.0 
     options:UIViewAnimationOptionTransitionNone
     animations:^{
            CGRect frame = self.view.frame;
            frame.origin.x=0;
            frame.origin.y=0;
            self.view.frame = frame;
        }
      completion:^(BOOL finished) {
        }
     ];
}

-(void)closeView
{
    [UIView animateWithDuration:MENU_SLIDE_DURATION
     delay:0.0 
     options:UIViewAnimationOptionTransitionNone
     animations:^{
            CGRect frame = self.view.frame;
            frame.origin.x = frame.size.width;
            frame.origin.y = frame.size.height;
            self.view.frame = frame;
        }
      completion:^(BOOL finished) {
            [self.view removeFromSuperview];
        }
     ];

    [[NSNotificationCenter defaultCenter] 
     postNotification:[NSNotification notificationWithName:MENU_CLOSE_EVENT object:nil]];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        // Custom initialization
        [self.view setBackgroundColor:[UIColor colorWithRed:(241/255.0) 
                                       green:(240/255.0) blue:(237/255.0) alpha:.8]];

        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] 
                                                        initWithTarget:self 
                                                        action:@selector(cancelPressed)];
        [self.cancel addGestureRecognizer:tapGestureRecognizer];
        tapGestureRecognizer = nil;

        tapGestureRecognizer = [[UITapGestureRecognizer alloc] 
                                initWithTarget:self 
                                action:@selector(player1Pressed)];
        [self.players1 addGestureRecognizer:tapGestureRecognizer];
        tapGestureRecognizer = nil;

        tapGestureRecognizer = [[UITapGestureRecognizer alloc] 
                                initWithTarget:self 
                                action:@selector(player2Pressed)];
        [self.players2 addGestureRecognizer:tapGestureRecognizer];
        tapGestureRecognizer = nil;

        tapGestureRecognizer = [[UITapGestureRecognizer alloc] 
                                initWithTarget:self 
                                action:@selector(playerNetworkPressed)];
        [self.playersNetwork addGestureRecognizer:tapGestureRecognizer];
        tapGestureRecognizer = nil;

        tapGestureRecognizer = [[UITapGestureRecognizer alloc] 
                                initWithTarget:self 
                                action:@selector(undoPressed)];
        [self.undo addGestureRecognizer:tapGestureRecognizer];
        tapGestureRecognizer = nil;
        
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] 
                                initWithTarget:self 
                                action:@selector(gameHelpPressed)];
        [self.help addGestureRecognizer:tapGestureRecognizer];
        tapGestureRecognizer = nil;

        tapGestureRecognizer = [[UITapGestureRecognizer alloc] 
                                initWithTarget:self 
                                action:@selector(musicToggle)];
        [self.musicBtn addGestureRecognizer:tapGestureRecognizer];
        tapGestureRecognizer = nil;
        
        tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                initWithTarget:self
                                action:@selector(peekPressed)];
        [self.peek addGestureRecognizer:tapGestureRecognizer];
        tapGestureRecognizer = nil;
    }
    return self;
}
-(void)disableButton:(UIImageView*)someBtn comingSoon:(BOOL)comingSoon
{
    someBtn.userInteractionEnabled = NO;
    someBtn.alpha=.6;

    if (comingSoon) 
    {
        UIImageView *comingSoon = [[UIImageView alloc] 
                                   initWithImage:[UIImage imageNamed:@"comingsoon.png"]];
        CGRect r = comingSoon.frame;
        double ratio = r.size.width/someBtn.frame.size.width;
        r.size.height *= ratio;
        r.size.width *= ratio;
        r.origin.y = (someBtn.frame.size.height-r.size.height)/2;
        r.origin.x = 2;
        comingSoon.frame = r;
        [someBtn addSubview:comingSoon];
        comingSoon=nil;
    }
}
-(void)enableButton:(UIImageView*)someBtn
{
    someBtn.userInteractionEnabled = YES;
    someBtn.alpha=1;

    // remove any coming-soon junk
    [[someBtn subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self updateMusicButtons];
}

-(IBAction)player1Pressed 
{
    self.button = Players1;
    [self closeView];
}
-(IBAction)player2Pressed 
{
    self.button = Players2;
    [self closeView];
}
-(IBAction)playerNetworkPressed
{
    self.button = PlayersNetwork;
    [self closeView];
}

-(IBAction)cancelPressed 
{
    self.button = Cancel;
    [self closeView];
}
-(IBAction)undoPressed 
{
    self.button = Undo;
    [self closeView];
}
-(IBAction)gameHelpPressed 
{
    self.button = GameHelp;
    [self closeView];
}
-(IBAction)peekPressed
{
    self.button = Peek;
    [self closeView];
}
-(IBAction)musicToggle 
{
    self.musicIsOn = (self.musicIsOn ? NO : YES);

    [self updateMusicButtons];

    [[NSNotificationCenter defaultCenter] 
     postNotification:[NSNotification notificationWithName:AUDIO_ON_OFF object:nil]];
}
-(void)dealloc
{
    [Blah nukeGestures:self.players1];
    [Blah nukeGestures:self.players2];
    [Blah nukeGestures:self.playersNetwork];
    [Blah nukeGestures:self.cancel];
    [Blah nukeGestures:self.undo];
    [Blah nukeGestures:self.help];
    [Blah nukeGestures:self.musicBtn];
    self.players1=nil;
    self.players2=nil;
    self.playersNetwork=nil;
    self.cancel=nil;
    self.undo=nil;
    self.help=nil;
    self.musicBtn=nil;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewWillAppear:(BOOL)animated
{
    CGPoint offset;
    CGRect frame = self.view.frame;

    if (self.ipad)
    {
        // @todo make a menuRight xib for ipad
        double factor = 1.74;

        for (UIView *subview in self.view.subviews) 
        {
            CGRect box = subview.frame;
            box.size.width *= factor;
            box.size.height *= factor;
            box.origin.x = (box.origin.x * factor) + 185; // yes a hack
            box.origin.y = (box.origin.y  * factor);
            subview.frame=box;
        }
    }
    else if (!self.smallPhone) //bah!
    {
        offset.x = (586-480)-10; // quick and very dirty
        offset.y = self.origin.y;
        self.view.frame=frame;

        for (UIView *subview in self.view.subviews) 
        {
            CGRect box = subview.frame;
            box.origin.x+=offset.x;
            box.origin.y= box.origin.y+offset.y;
            subview.frame=box;
        }
    }
}
@end
