//
//  ViewController.m
//  ChipFlip
//
//  Created by Secret Chess on 5/31/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>

#import "ChipViewController.h"
#import "InfoViewViewController.h"
#import "SavedGame.h"
#import "AppDelegate.h" // for GCHelper

@interface ChipViewController ()
{
    BOOL _iPad;
    BOOL _smallPhone;
    BOOL _musicIsOn;

    CGPoint _origin;
    CGRect _boardFrame;
    CGSize _chipSize;

    AIPlayer *_aiPlayer;
    GameBoard *_gameBoard;
    GameManager *_gameManager;
    NSArray *_outlines;// = [self.gameboard getChipOutlines];

    OutlinesView *_baseOutline;   // for ray
    OutlinesView *_outlineView;   // 'live' during drag

    LoadingViewJ *_mask;         // don't touch while AI thinking

    MenuViewController *_menu;
    SavedGames *_savedGames;
    AVAudioPlayer *_audioPlayer;
}
@property CGPoint origin;
@property CGRect boardFrame;
@property CGSize chipSize;

@property (retain) NSArray *outlines;
@property (retain) GameBoard *gameBoard;
@property (retain) OutlinesView *baseOutline;              
@property (retain) OutlinesView *outlineView;              
@property (retain) GameManager *gameManager;
@property (retain) AVAudioPlayer *audioPlayer;
@property (retain) MenuViewController *menu;
@property (retain) SavedGames *savedGames;

@property (retain) AIPlayer *aiPlayer;
@property LoadingViewJ *mask;
@property BOOL iPad;
@property BOOL smallPhone;
@property BOOL musicIsOn;

-(int)randomPosition;
-(void)newGame;
-(void)newGameBoard;
-(void)prepareChips:(BOOL)createChips;
-(void)createGridlines:(BOOL)fixed;
-(void)baseGrid;
-(void)showGridlines;
-(void)hideGridlines;
-(BOOL)restoreNamedGame;
-(void)deleteNamedGame;

-(void)chipDragStart;
-(void)chipDragStop;
-(void)chipDragCancel;
-(void)chipDragMove;
-(void)chipFlipped;

-(void)nextTurn;
-(void)displayGameOver;
-(void)clearGameOver;

-(void)processMenuChoice;
-(void)processSavedGameChoice;

-(void)saveGame:(BOOL)gameOver;

-(void)infoPage;
-(void)peek;
-(void)menuPage;
-(void)savedGamesPage:(NSArray*)games;
-(void)audioHandler;

-(void)runAI;

@end

@implementation ChipViewController

-(void)audioHandler
{
    if (self.menu.musicIsOn) 
    {        
        // Create a player on demand only
        NSURL *url = [[NSBundle mainBundle] URLForResource:AUDIO_CLIP withExtension:AUDIO_TYPE];
        AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:NULL];
        if (audioPlayer)
        {
            audioPlayer.numberOfLoops = -1;            
            self.audioPlayer = audioPlayer;
            self.musicIsOn=YES;                
            [self.audioPlayer play];
            self.audioPlayer.volume = VOLUME;

            audioPlayer=nil; // cleanup
        }
        else {
            // Some kind of warning? Shouldn't happen
        }
    }
    else 
    {
        if (self.audioPlayer)
        {
            [self.audioPlayer stop];
            self.audioPlayer=nil; // killed so radio/iPod can play
        }
        self.musicIsOn=NO;                
    }
}
-(void)deleteNamedGame
{
    if (!self.savedGames) 
    {
        NSLog(@"wtf");
        return;
    }

    AGame *game = [self.savedGames.games objectAtIndex:self.savedGames.deleted];
    [StateManager deleteGameState:game.name];

    NSArray *savedGames = [StateManager savedGames];
    self.savedGames.deleted = -1;
    self.savedGames.games = savedGames;
    [self.savedGames.table reloadData];
    self.savedGames.choice = None;
}
-(BOOL)restoreNamedGame
{
    BOOL result  = NO;

    if (!self.savedGames) {
        NSLog(@"wtf?");
    }
    else
    {
        [self clearGameOver];
        [self newGameBoard];
        AGame *game = [self.savedGames.games objectAtIndex:self.savedGames.selected];
        
        if (![StateManager restoreGameState:self.gameManager name:game.name]) {
            NSLog(@"wtf!");
        }
        else
        {
            self.gameName.text = game.name;
            self.gameManager.gameType = [StateManager savedGameType];
            
            // builds chip images, clobbers some things
            [self prepareChips:NO];
            
            self.gameManager.currentPlayerColor = self.gameManager.currentPlayerColor;
            [self.gameManager isGameOver];
            [self updateWhoseTurn];
            
            if ([self.gameManager isGameOver]) {
                [self displayGameOver];
            }
            [self baseGrid];
            
            result = YES;
        }
    }
    return result;
}
-(void)processSavedGameChoice
{
    GameChoice btn = self.savedGames.choice;
    switch (btn)
    {
     case PlaySaved:
         [self.gameManager clearUndo];
         if (![self restoreNamedGame]){
             [self menuPage];
         }
         break;
     case PlayNew:
         [self.gameManager clearUndo];
         self.gameManager.gameType = TwoLocal;
         self.gameName.text = [NSString stringWithFormat:@"%@ vs %@", self.savedGames.you,
                              self.savedGames.them];
         [self newGame];
         break;
     case None:
     default:
         break;
    }
    self.savedGames.games=nil;
    self.savedGames = nil;
}

-(void)processMenuChoice
{
    ButtonPressed btn = self.menu.button;
    self.menu = nil;

    switch (btn)
    {
     case Players1:
         self.gameManager.gameType = OneLocal;
         self.gameName.text = USER_VS_GAME;
         [self newGame];
         [self saveGame:NO];
         break;
     case Players2:
         [self savedGamesPage:[StateManager savedGames]];
         break;
     case PlayersNetwork:
         self.gameManager.gameType = RemoteGame;
         [self savedGamesPage:[StateManager savedGames]];
         break;
     case Undo:
         if ([self.gameManager canPop]) 
         {
             [self.gameManager pop];
             [self saveGame:NO];
             [self updateWhoseTurn];
         }
         break;
     case GameHelp:
         [self infoPage];
         break;
     case Peek:
         [self peek];
         break;
     case Players2Pick:
     case Cancel:
         break;
    }
}
-(void)savedGamesPage:(NSArray*)games
{
    SavedGames *savedGames = [[SavedGames alloc] initWithNibName:@"SavedGames" bundle:nil];
    self.savedGames = savedGames;
    self.savedGames.games = games;
    savedGames = nil;

    CGRect frame = self.savedGames.view.frame;
    CGRect screen = [[UIScreen mainScreen] bounds];
    frame.size.width=screen.size.height; // landscape swap
    frame.size.height=screen.size.width;
    frame.origin.y = -frame.size.height;
    self.savedGames.view.frame=frame;

    self.savedGames.ipad  = self.iPad;
    self.savedGames.smallPhone = self.smallPhone;
    self.savedGames.origin = self.origin;
    [self.view addSubview:self.savedGames.view];

    [UIView animateWithDuration:MENU_SLIDE_DURATION
     delay:0.0 
     options:UIViewAnimationOptionTransitionNone
     animations:^{
            CGRect frame = self.savedGames.view.frame;
            frame.origin.y=0;
            self.savedGames.view.frame = frame;
        }
      completion:^(BOOL finished) {
        }
     ];
}
-(void)menuPage
{
    MenuViewController *menuController = [[MenuViewController alloc] 
                                          initWithNibName:@"MenuViewControllerRight" bundle:nil];
    self.menu = menuController;
    menuController = nil;

    CGRect frame = self.menu.view.frame;
    CGRect screen = [[UIScreen mainScreen] bounds];
    frame.size.width=screen.size.height; // landscape swap
    frame.size.height=screen.size.width;
    self.menu.view.frame=frame;
        
    self.menu.ipad = self.iPad;
    self.menu.smallPhone = self.smallPhone;
    self.menu.origin = self.origin;

    if ([self.gameManager canPop]){
        [self.menu enableButton:self.menu.undo];
    }
    else {
        [self.menu disableButton:self.menu.undo comingSoon:NO];
    }

    // this boolean conveys data between menu and main views
    self.menu.musicIsOn = (self.musicIsOn ? YES : NO);

    if (!INTERNET_PLAYER){
        [self.menu disableButton:self.menu.playersNetwork comingSoon:YES];
    }
    else 
    {
        if ([AppDelegate instance].userAuthenticated) {
            NSLog(@"user logged in allow online games");
        }
        else {
            [self.menu disableButton:self.menu.playersNetwork comingSoon:NO];
        }
    }

    /* BUGBUG: RAYSUN: re-enabling 1 player temporarily for beta users while 2 player over Internet is not enabled
    if (!ONE_PLAYER) {
        [self.menu disableButton:self.menu.players1 comingSoon:YES];
    }
     */

    // want the view to sit on current game board view, not replace it
    [self.menu addToWithEffect:self.view];

    [self.menu updateMusicButtons];
}
-(void)peek {
    [[self gameManager] performSelector:@selector(peekBoard) withObject:nil afterDelay:.25];
}
-(void)infoPage 
{
    InfoViewViewController *info = [[InfoViewViewController alloc] init];
    [self presentViewController:info animated:YES completion:nil];
    info=nil;
}
// @todo when this is remote, save game then sync gamecenter
-(void)saveGame:(BOOL)gameOver
{
    if (LOG) {
        NSLog(@"saving game");
    }
    [StateManager saveGameState:self.gameManager type:self.gameManager.gameType 
     gameOver:gameOver name:self.gameName.text];
}

-(void)chipFlipped;
{
    if (!IsOnePerson(self.gameManager)){
        [self.gameManager push];
    }
    Chip *chip = [self.gameBoard getItemByIdent:[Chip activeChip]];
    
    if (chip){
        [chip flipChip];
    }
    [self nextTurn];
    [Chip clear];
}
-(void)newGame
{
    [self clearGameOver];

    [self newGameBoard];
    [self prepareChips:YES];
    [self baseGrid];

    [self.gameBoard syncBoardCells];

    self.underBar.hidden=NO;
}

-(void)newGameBoard
{
    if (self.gameBoard) 
    {
        [self.gameBoard clear];
        self.gameBoard = nil;
        self.gameManager.gameBoard = nil;
    }
    if (self.aiPlayer){
        self.aiPlayer=nil;
    }

    // just in case
    AIPlayer *player = [[AIPlayer alloc]init];
    self.aiPlayer = player;
    player=nil;
    self.aiPlayer.gameManager = self.gameManager;

    GameBoard *board = [GameBoard buildBoard:self.chipSize origin:self.origin];
    self.gameBoard = board;
    self.gameManager.gameBoard = board;
    self.gameManager.physicalBoard = self.view;
    board=nil;
}

-(void)updateWhoseTurn 
{
    // this logic depends on the bar UI being presented under an image/indicator
    CGRect frame = self.underBar.frame;
    if (self.gameManager.currentPlayerColor==RED){
        frame.origin.x = self.turnPlayer.frame.origin.x;
    }
    else {
        frame.origin.x = self.turnPlayer2.frame.origin.x;
    }
    self.underBar.frame=frame;
}
-(void)clearGameOver 
{
    self.msg.hidden=YES;
    self.msg.text=nil;    
}
-(void)displayGameOver
{
    // Needs localizing!
    NSString *winner = [NSString stringWithFormat:@"%@ is the winner!",
                        (self.gameManager.totalRed != 0 ? @"Red" : @"Blue")];
    self.msg.text = winner;
    self.msg.hidden=NO;
    [self.view addSubview:self.msg]; // force to top if not

    self.underBar.hidden=YES;
}
-(void)nextTurn
{
    if (IsOnePerson(self.gameManager) && self.mask)
    {
        if (LOG) {
            NSLog(@"busy!");
        }
        return;
    }

    [self.gameManager nextTurn];
    [self updateWhoseTurn];

    if ([self.gameManager isGameOver])
    {
        [self displayGameOver];
        [self saveGame:YES];
        [self menuPage];
    }
    else 
    {
        if (LOG) {
            NSLog(@"%@'s turn", [Chip colorToString:self.gameManager.currentPlayerColor]);
        }

        [self saveGame:NO];

        // This temp transparent thing on top prevents any interaction on the
        // board while the AI thinks (which causes event issues); the happy side effect 
        // for Julie is visual feedback while the AI thinks (so don't remove)
        if (IsOnePerson(self.gameManager) && self.gameManager.currentPlayerColor==BLUE) 
        {
            CGRect frame;
            frame.origin = self.origin;
            frame.size.width = self.chipSize.width*COLS;
            frame.size.height = self.chipSize.height*ROWS;
 
            self.mask = [LoadingViewJ loadingViewInViewWithBounds:self.view 
                         bounds:frame];
            [self performSelector:@selector(runAI) withObject:nil afterDelay:MOVE_THINK];
        }
    }

}
-(void)chipDragMove
{
    Chip *attacker=nil;
    Chip *defender = nil;

    attacker = [self.gameBoard getItemByIdent:[Chip activeChip]];
    if (!attacker) {
        // shouldn't happen
    }
    else {
        defender = [self.gameBoard getItemByPt:attacker.imageView.center];
    }

    if (LOG) {
        NSLog(@"%@%@ over %@%@",
              [Chip colorToString:attacker.color], [Chip chipToString:attacker.player], 
              [Chip colorToString:defender.color], [Chip chipToString:defender.player]);
    }

    if (defender) 
    {
        self.outlineView.outlines = nil;

        PlayerMove move;
        
        // don't let the human steal the move
        if (IsOnePerson(self.gameManager) && attacker.color != RED) 
        {
            if (LOG) {
                NSLog(@"not your turn human");
            }
            move = NotYourTurn;
        }
        else {
            move = [self.gameManager evaluateMove:attacker defender:defender
                    color:self.gameManager.currentPlayerColor
                    ignoreGeometry:NO];
        }
        
        if (move==NotYourTurn)
        {
            self.outlineView.outlines = self.outlines; 
            [self.outlineView setColor:1.0 green:0.0 blue:0.0 alpha:GRID_ALPHA width:GRID_LINE_WIDTH];
        }
        else if (move==IllegalMove || move==NotYourTurn)
        {
            self.outlineView.outlines = [self.gameBoard getChipOutline:defender];
            [self.outlineView setColor:1.0 green:0.0 blue:0.0 alpha:GRID_ALPHA width:GRID_LINE_WIDTH];
        }
        else if (move==SameSpot || move==OutOfBounds)
        {
            self.outlineView.outlines = self.outlines; // drag grid restored
            [self.outlineView setColor:GRID_RED green:GRID_GREEN 
                                  blue:GRID_BLUE alpha:GRID_ALPHA 
                                  width:GRID_LINE_WIDTH];
        }
        else // all others legal
        {
            self.outlineView.outlines = [self.gameBoard getChipOutline:defender];
            [self.outlineView setColor:0.0 green:1.0 blue:0.0 alpha:GRID_ALPHA width:GRID_LINE_WIDTH];
        }
        // @todo optimize, only do if state changed
        [self.outlineView setNeedsDisplay];
    }
}
-(void)baseGrid
{
    if (self.outlines){
        self.outlines=nil;
    }
    // put the bottom-most grid now (for ray)
    NSArray *outlines = [self.gameBoard getChipOutlines];
    self.outlines = outlines;
    outlines=nil;
    [self createGridlines:YES];            
    [self.baseOutline setNeedsDisplay]; // make sure these redrawn
}
-(void)chipDragStart {
    [self showGridlines];
}
-(void)chipDragStop
{
    [self hideGridlines];

    Chip *attacker = [self.gameBoard getItemByIdent:[Chip activeChip]];
    if (attacker) 
    {
        BOOL moveCompleted=NO;
        Chip *defender = [self.gameBoard getItemByPt:attacker.imageView.center];
        
        if (LOG) {
            NSLog(@"%@%@ on %@,%@", 
                  [Chip colorToString:attacker.color], [Chip chipToString:attacker.player], 
                  [Chip colorToString:defender.color], [Chip chipToString:defender.player]);
        }
        
        PlayerMove moveResult = IllegalMove;
        if (IsOnePerson(self.gameManager) && attacker.color != RED) 
        {
            if (LOG) {
                NSLog(@"not your turn human");
            }
        }
        else
        {
            if (defender)
            {
                if (defender.ident!=attacker.ident) 
                {
                    moveResult = [self.gameManager evaluateMove:attacker 
                                  defender:defender
                                  color:self.gameManager.currentPlayerColor
                                  ignoreGeometry:NO];
                    
                    if (moveResult==AttackerWins || moveResult==EmptyTaken)
                    {
                        if (!IsOnePerson(self.gameManager)){
                            [self.gameManager push];
                        }
                        [self.gameManager executeMove:attacker defender:defender];
                        moveCompleted=YES;
                    }
                }
            }
        }

        // move over
        if (moveCompleted) 
        {
            [self nextTurn]; // mark next turn before save
            [self saveGame:NO];
        }
        else {
            [attacker fixViewRect];
        }

        [Chip clear];
    }
}
-(void)chipDragCancel 
{
    [self hideGridlines];
    [Chip clear];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    srand(time(NULL)); // randomizer for prepareChips

    [self clearGameOver];
}
-(void)hideGridlines 
{
    if (self.outlineView)
    {
        self.outlineView.outlines=nil;
        [self.outlineView removeFromSuperview];
    }
}
-(void)showGridlines {
    [self createGridlines:NO];
}
-(void)createGridlines:(BOOL)fixed
{
    CGRect frame = self.boardFrame;

    // gameboard origin - adjust for this view's bounds in gameboard
    float left = self.origin.x;
    frame.size.width += left;
    if (!self.iPad && !self.smallPhone) {
        frame.size.width += GRID_LINE_WIDTH/2; //allowance for width of outlines drawn
    }
    frame.origin.x = 0;

    OutlinesView *outlineView;

    // live means the grid being dragged
    if (!fixed)
    {
        if (self.outlineView)
        {
            [self.outlineView removeFromSuperview];
            self.outlineView = nil;
        }
        outlineView = [[OutlinesView alloc] initWithFrame:frame
                       red:GRID_RED 
                       green:GRID_GREEN 
                       blue:GRID_BLUE 
                       alpha:GRID_ALPHA
                       width:GRID_LINE_WIDTH];
        self.outlineView = outlineView;
        [self.view addSubview:outlineView];
    }
    // the static dim grid to define the game space
    else
    {
        if (self.baseOutline)
        {
            [self.baseOutline removeFromSuperview];
            self.baseOutline=nil;
        }
        outlineView = [[OutlinesView alloc] initWithFrame:frame
                       red:GRID_DIM_RED 
                       green:GRID_DIM_GREEN 
                       blue:GRID_DIM_BLUE 
                       alpha:GRID_DIM_ALPHA
                       width:GRID_DIM_LINE_WIDTH];
        
        self.baseOutline = outlineView;
        [self.view insertSubview:outlineView atIndex:GRID_DIM_Z_ORDER];
    }

    outlineView.outlines = self.outlines;
    outlineView = nil;
}

// iOS 7 strikes again - root view needs to use this regardless of xib setup
- (BOOL)prefersStatusBarHidden {
    return YES;
}
// could be nice and deallocate ram on swap out but don't care
- (void)viewDidAppear:(BOOL)animated 
{
    if (!self.gameBoard)
    {
        GameManager *gameManager = [[GameManager alloc] init];
        self.gameManager = gameManager;
        gameManager=nil;

        UIDevice *current = [UIDevice currentDevice];
        NSRange r = [[current model] rangeOfString:@"iPad"];
        float originalWidth;
        self.iPad =  (r.length > 0);
        self.smallPhone = YES;

        CGRect frame = [[UIScreen mainScreen] bounds];

        // landscape, flip the sizes. groan
        if (frame.size.height > frame.size.width)
        {
            float s = frame.size.height;
            frame.size.height = frame.size.width;
            frame.size.width = s;

            originalWidth = frame.size.width;

            // hackery disgusting iPhone5 support
            if (!self.iPad)
            {
                if (frame.size.width > 480) 
                {
                    frame.size.width = 480;
                    self.smallPhone = NO;
                }
            }
        }
        else {
            originalWidth = frame.size.width;
        }

        self.boardFrame = frame;

        // all chips are the same size; adjust for the game board
        UIImage *chip = [UIImage imageNamed:FACE_DOWN_IMAGE];
        int maxwidth = floor(frame.size.width/COLS);

        double ratio = maxwidth/chip.size.width;
        float width = chip.size.width*ratio;
        float height = chip.size.height*ratio;
        self.chipSize = CGSizeMake(width, height);
        // gameboard origin - center in screen
        if (!self.smallPhone)
        {
            self.origin = CGPointMake(frame.origin.x + (originalWidth-frame.size.width)/2, 
                                      frame.origin.y + GAME_GRID_TOP_OFFSET(self.iPad));
        }
        else {
            self.origin = CGPointMake(frame.origin.x, 
                                      frame.origin.y + GAME_GRID_TOP_OFFSET(self.iPad));
        }

        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] 
                                                        initWithTarget:self 
                                                        action:@selector(menuPage)];
        [self.openbtn addGestureRecognizer:tapGestureRecognizer];
        tapGestureRecognizer = nil;

        // the game  @todo by local or remote saved
        NSArray *savedGames = [StateManager savedGames];
        [self newGameBoard];

        if (savedGames && [savedGames count] > 0) 
        {
            [self prepareChips:NO];
            [self savedGamesPage:savedGames];
        }
        else 
        {
            [self prepareChips:YES];
            if (ONE_PLAYER) {
                self.gameManager.gameType = OneLocal;
            }
            else 
            {
                self.gameManager.gameType = TwoLocal;
                self.gameName.text = [NSString stringWithFormat:@"%@ vs %@", DEFAULT_YOU_NAME,
                                      DEFAULT_THEM_NAME];
            }
            [self menuPage];
            [self baseGrid];
        }

        // chip moving stuff
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chipDragStart) 
         name:CHIP_DRAG_START object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chipDragMove) 
         name:CHIP_DRAG_MOVE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chipDragStop) 
         name:CHIP_DRAG_STOP object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chipDragCancel) 
         name:CHIP_DRAG_CANCEL object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chipFlipped) 
         name:CHIP_FLIPPED object:nil];

        // menu actions
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processMenuChoice) 
                                                     name:MENU_CLOSE_EVENT object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(processSavedGameChoice) 
        name:SAVED_GAME_CLOSED object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteNamedGame) 
                                                     name:DELETE_GAME object:nil];

        // audio
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioHandler) 
         name:AUDIO_ON_OFF object:nil];
    }
}
-(void)prepareChips:(BOOL)createChips
{
    // chips already in place if createChips==NO
    BOOL done= (createChips ? NO : YES);
    PlayerColor currentColor = RED;
    int chipPlaced=0;

    // randomize positions until all colors placed
    while (!done)
    {
        Player p = General;
        int countForType = [Chip countByType:p];
        while (p >= Infantry)
        {
            int cell = [self randomPosition];
            int row = cell/COLS;
            int col = floor(cell%COLS);
            Chip *chip = [self.gameBoard getItemAt:row col:col];

            if (chip.player==Empty)
            {
                chipPlaced++;
                Chip* newChip = [[Chip alloc] initWithPlayer:p color:currentColor];
                [self.gameBoard replaceItem:chip with:newChip];
                [chip removeFromBoard];
                newChip=nil;

                // next type ?
                countForType--;
                if (countForType < 1) 
                {
                    p--;
                    countForType = [Chip countByType:p];
                }
            }
            // else keep trying
        }

        if (currentColor==BLUE){
            done=YES;
        }
        else {
            currentColor=BLUE;
        }
    }

    // randon start player
    if (createChips)
    {
        PlayerColor startColor;
        if (IsOnePerson(self.gameManager))
        {
            if (LOG) {
                NSLog(@"human starts new game as red");
            }
            startColor=RED;
        }
        else 
        {
            if (rand() % 2 == 1){
                startColor=RED;
            }
            else {
                startColor=BLUE;
            }
        }
        self.gameManager.currentPlayerColor = startColor;
        
        // count players, etc, dim chips not active etc
        [self.gameManager isGameOver];
        [self updateWhoseTurn];
    }

    // create the chip images now
    for (int row=0; row < ROWS; row++)
    {
        for (int col=0; col < COLS;col++)
        {
            Chip *chip = [self.gameBoard getItemAt:row col:col];
            if (chip)
            {
                [chip addImage:self.origin row:row col:col size:self.chipSize];
                // placing them onscreen now
                [self.view addSubview:chip.imageView];
                [chip adjustNotifiers];
            }
        }
    }
    [self.gameBoard syncBoardCells];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if (self.gameManager)
    {
        while ([self.gameManager trim] > 1){ // all but 1
        }
    }
}
// generates the cell position
-(int)randomPosition
{
    int mx = (ROWS*COLS);
    for (int i = 0; i < 4; i++) // 4 times else die
    {
        int result = rand() % mx;
        if (result < mx){
            return result;
        }
    }
    return -1; // wtf
}

- (BOOL)shouldAutorotate {
    return YES;
}
-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods{
    return YES;
}
-(void)runAI
{
    [self.mask removeView];
    self.mask = nil;

    if ([self.aiPlayer makeMove])
    {
        Chip *attacker = [self.aiPlayer getAttacker];
        Chip *defender = [self.aiPlayer getDefender];
        
        if (!defender) 
        {
            // attacker chip just turned over 
            [attacker flipChip];
            
            // sign, no notification
            [self.gameBoard syncBoardCells];
            
            [self nextTurn]; // mark next turn before save
            [self saveGame:NO];
        }
        else
        {
            // confirm
            PlayerMove moveResult = [self.gameManager evaluateMove:attacker 
                                     defender:defender 
                                     color:self.gameManager.currentPlayerColor
                                     ignoreGeometry:NO];
            if (moveResult==AttackerWins || moveResult==EmptyTaken)
            {
                [self updateWhoseTurn];
                
                // To make things look right, the image of this chip should be topmost
                // else it appears to drag under chips placed on the board after it; this
                // causes a reordering
                [attacker moveOnTop];

                [UIView animateWithDuration:AUTO_MOVE_DURATION
                 delay:0.0 
                 options:UIViewAnimationOptionTransitionNone
                 animations:^{
                        //[self.gameManager executeMove:attacker defender:defender];
                        [self.gameBoard moveItem:attacker to:defender];    
                    }
                  completion:^(BOOL finished) {
                        [self nextTurn]; // mark next turn before save
                        [self saveGame:NO];                                        
                        
                        [UIView animateWithDuration:AUTO_MOVE_DURATION
                         delay:0.0 
                         options:UIViewAnimationOptionTransitionNone
                         animations:^{
                                [self updateWhoseTurn];
                            }
                          completion:^(BOOL finished) {
                                [defender removeFromBoard];
                            }
                         ];
                    }
                 ];
            }
        }
    }
    // bug or just nothing to do?
    else 
    {
        self.msg.text = @"Blue passes!";
        self.msg.hidden=NO;
        [self.view addSubview:self.msg]; // force to top if not

        [UIView animateWithDuration:ERROR_MSG
         delay:0.0 
         options:UIViewAnimationOptionTransitionNone
         animations:^{                
                self.msg.alpha=0;
            }
          completion:^(BOOL finished) {                
                [self clearGameOver];

                [self nextTurn]; // mark next turn before save
                [self saveGame:NO];

                [UIView animateWithDuration:AUTO_MOVE_DURATION
                 delay:0.0 
                 options:UIViewAnimationOptionTransitionNone
                 animations:^{
                        [self updateWhoseTurn];
                    }
                  completion:^(BOOL finished) {
                    }
                 ];
            }
         ];
    }
}

@end

@implementation OutlinesView
-(void)setColor:(float)red 
          green:(float)green blue:(float)blue 
          alpha:(float)alpha width:(float)width
{
    _red = red;
    _green = green;
    _blue = blue;
    _alpha = alpha;
    _width = width;
}
-(id)initWithFrame:(CGRect)frame red:(float)red 
                           green:(float)green blue:(float)blue 
                           alpha:(float)alpha width:(float)width
{
    if (self = [super initWithFrame:frame])
    {        
        self.outlines=nil;
        [self setColor:red green:green blue:blue alpha:alpha width:width];
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

-(void)drawRect:(CGRect)rect 
{
    if (self.outlines)
    {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetRGBStrokeColor(context, _red, _green, _blue, _alpha);
        for (NSValue *value in self.outlines) 
        {
            CGRect box = [value CGRectValue];
            CGContextStrokeRectWithWidth(context, box, _width);
        }
    }
}
-(void)dealloc {
    self.outlines=nil;
}

@end
