//
//  SavedGame.m
//  SecretChess
//
//  Created by Secret Chess on 7/27/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import "SavedGame.h"
#import "Constants.h"
#import "StateManager.h"

@interface SavedGames ()

-(void)closeView;
@end

@implementation SavedGames
-(void)closeView
{
    [UIView animateWithDuration:MENU_SLIDE_DURATION
     delay:0.0 
     options:UIViewAnimationOptionTransitionNone
     animations:^{

            CGRect frame = self.view.frame;
            frame.origin.y = -frame.size.height;
            self.view.frame = frame;
        }
      completion:^(BOOL finished) {
            [[NSNotificationCenter defaultCenter] 
             postNotification:[NSNotification notificationWithName:SAVED_GAME_CLOSED object:nil]];
            [self.view removeFromSuperview];
        }
     ];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        // Custom initialization
        self.selected = -1;
        self.deleted = -1;
    }
    return self;
}
- (void)viewWillAppear:(BOOL)animated 
{
    if (self.games) {
        [self.table reloadData];
    }

    CGRect frame = self.table.frame;
    frame.size.width = self.view.frame.size.width/2;
    self.table.frame = frame;
    CGPoint offset;

    if (self.ipad)
    {
        // @todo make a menuRight xib for ipad
        double factor = 1.74;

        for (UIView *subview in self.view.subviews) 
        {
            CGRect box = subview.frame;
            box.size.width *= factor;
            box.size.height *= factor;
            box.origin.x = (box.origin.x * factor) + 40; // yes a hack
            box.origin.y = (box.origin.y  * factor);
            subview.frame=box;
        }
        frame = self.table.frame;
        frame.size.height = 600;//-= 200; //more hacking
        frame.size.width = 550;
        self.table.frame = frame;
    }
    else if (!self.smallPhone)
    {
        offset.x = (586-480)/3; // quick and very dirty centering
        offset.y = self.origin.y;

        for (UIView *subview in self.view.subviews) 
        {
            CGRect box = subview.frame;
            box.origin.x+=offset.x;
            box.origin.y= box.origin.y+offset.y;
            subview.frame=box;
        }

        frame = self.table.frame;
        frame.size.width -= offset.x/2; //more hacking
        self.table.frame = frame;
    }
}
-(IBAction)playGame
{
    self.choice=PlayNew;

    if (self.redplayer.text){
        self.you = [self.redplayer.text stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if (self.blueplayer.text) {
        self.them = [self.blueplayer.text stringByTrimmingCharactersInSet:
                     [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if ([self.you length] < 1){
        self.you = @"You";
    }
    if ([self.them length] < 1){
        self.them = @"Them";
    }

    self.redplayer.text = self.you;
    self.blueplayer.text = self.them;

    // @todo validate user just didn't create a dupe game name? or just kill the old one!

    [self.view endEditing:YES];

    [self closeView];
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
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	//NSLog(@"game %d", indexPath.row);
    self.selected = indexPath.row;
    self.choice = PlaySaved;
    [self closeView];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.games count];
}
- (UITableViewCell *)tableView:(UITableView *)aTableView 
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	static NSString *kCellID = @"CellID";	 

	UITableViewCell *cell = [self.table dequeueReusableCellWithIdentifier:kCellID];
	if (cell == nil) 
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
				reuseIdentifier:kCellID];
	}

	AGame *aGame = [self.games objectAtIndex:indexPath.row];
    cell.textLabel.backgroundColor=[UIColor clearColor];
    cell.textLabel.text = aGame.name;

    cell.detailTextLabel.backgroundColor=[UIColor clearColor];
    cell.detailTextLabel.text = aGame.detail;

	return cell;
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView 
         editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}
- (void)tableView:(UITableView *)tableView 
        commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
         forRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.choice = None;
    self.deleted = indexPath.row;
    [[NSNotificationCenter defaultCenter] 
     postNotification:[NSNotification notificationWithName:DELETE_GAME object:nil]];
}

@end
