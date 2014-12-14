//  Created by Secret Chess on 6/1/13.
//  Copyright (c) 2013 Secret Chess. All rights reserved.

/* some typedefs that define player pieces
 */
#define ROWS 4
#define COLS 8
#define PLAYER_PER_COLOR ((ROWS*COLS)/2)

typedef enum playerColor
{
    NONE,
    RED,
    BLUE
} PlayerColor;

typedef enum playerState
{
    FACE_DOWN,
    FACE_UP
} PlayerState;


// rank, beats player below it except Infantry can beat a King
typedef enum player
{                    // count      traditional worth
    General = 7,     // 1 
    Advisor = 6,     // 2              2
    Elephant = 5,    // 2              2
    Chariot = 4,     // 2              9
    Horse = 3,       // 2              4
    Artillery = 2,   // 2              4
    Infantry = 1,    // 5              1

    Empty = 10
} Player;

typedef enum move
{
    AttackerWins,
    DefenderWins,
    EmptyTaken,
    NotYourTurn,
    IllegalMove,
    SameSpot,
    OutOfBounds
} PlayerMove;


