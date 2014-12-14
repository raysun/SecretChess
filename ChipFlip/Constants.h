//  Created by Secret Chess on 5/31/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.
//
// UI etc constants that deal with app behavior
//
#define LOG NO//DEBUG

#define ONE_PLAYER NO //YES  //off first release
#define INTERNET_PLAYER YES
#define DEFAULT_YOU_NAME @"red"
#define DEFAULT_THEM_NAME @"blue"

#define VERSION @"0.5"

#define MENU_CLOSE_EVENT @"me"
#define MENU_SLIDE_DURATION .6
#define GAME_NAME_CLOSE @"gnc"
#define SAVED_GAME_CLOSED @"sgc"
#define DELETE_GAME @"delg"
#define INFO_CLOSED @"infc"

//  grid rendering
#define GRID_DIM_LINE_WIDTH (1)
#define GRID_DIM_Z_ORDER 0         // nothing under it
#define GRID_DIM_RED (170/255)
#define GRID_DIM_BLUE (170/255)
#define GRID_DIM_GREEN (170/255)
#define GRID_DIM_ALPHA .8

// generic drag
#define GRID_LINE_WIDTH (2)
#define GRID_RED (51/255)
#define GRID_BLUE (125/55)
#define GRID_GREEN (94/255)
#define GRID_ALPHA 1.0

#define CHIP_DRAG_START @"ds"
#define CHIP_DRAG_STOP @"sd"
#define CHIP_DRAG_MOVE @"dm"
#define CHIP_DRAG_CANCEL @"dc"
#define CHIP_FLIPPED @"cf"

#define RED_PREFIX @"red"               // image prefix names by color duh
#define BLUE_PREFIX @"blue"
#define FACE_DOWN_IMAGE @"faceDown.png" // face up images are the names computed from color,player
#define CHIP_FLIP_SPEED 0.3f

#define REVEAL_UNDO_DELAY 1
#define REVEAL_DURATION .25
#define REVEAL_UNDO_DURATION 2

// chipsize - 
#define CELL_INSET 4.0 // if chip image larger than cell, push it smaller

// view dragging stuff
#define VIEW_DRAG_START @"vs"
#define VIEW_DRAG_STOP @"vd"
#define VIEW_DRAG_MOVE @"vm"
#define VIEW_DRAG_CANCEL @"vc"
#define VIEW_DRAG_DONE @"ve"

#define VIEW_SLIDE_BACK_TIME .6
#define VIEW_DROP_DOWN_TIME .2

#define VIEW_DRAG_MARGIN(iPad) (iPad ? 80 : 60.0)        // how far from edge is in-view
#define GAME_GRID_TOP_OFFSET(iPad) (iPad ? 20 : 5)
#define RANK_HINT_SHOW_DURATION .5
#define RANK_HINT_HIDE_DURATION 2.5

#define ERROR_MSG 2.5
#define AUTO_MOVE_DURATION .6
#define MOVE_THINK .33        // artificial delay so AI isn't too fast
//////////////////////////////////////

#define MAX_UNDO 10
#define NO_UNDO_ALPHA .5

// not too loud please
#define AUDIO_ON_OFF @"au"
#define VOLUME (.2)
#define AUDIO_CLIP  @"popcorn"
#define AUDIO_TYPE @"m4a"

#define VIDEO_HELP @"http://youtu.be/nqNIBt03uVk"

// chip debug
#define DEBUG_BLANK_CHIP NO//YES
#if (DEBUG_BLANK_CHIP)
#  define BLANK_CHIP @"yellow.png"//@"Transparent.png"
#else
#  define BLANK_CHIP @"Transparent.png"
#endif

// some stuff to localize
#define USER_VS_GAME @"You vs SecretChess"
#define ONE_LOCAL @"secret"
#define TWO_LOCAL @"1 vs 1"
#define TWO_NETWORK @"cloud"

