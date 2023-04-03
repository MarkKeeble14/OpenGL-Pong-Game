//
//  Copyright © Borna Noureddin. All rights reserved.
//

#ifndef MyGLGame_CBox2D_h
#define MyGLGame_CBox2D_h

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

// Set up brick and ball physics parameters here:
//   position, width+height (or radius), velocity,
//   and how long to wait before dropping brick

#define PADDLE_LEFT_POS_X            100
#define PADDLE_LEFT_POS_Y            300
#define PADDLE_LEFT_WIDTH            10.0f
#define PADDLE_LEFT_HEIGHT           100.0f

#define PADDLE_RIGHT_POS_X            700
#define PADDLE_RIGHT_POS_Y            300
#define PADDLE_RIGHT_WIDTH            10.0f
#define PADDLE_RIGHT_HEIGHT         100.0f

#define GOAL_RIGHT_POS_X    750
#define GOAL_RIGHT_POS_Y    300
#define GOAL_RIGHT_WIDTH    10
#define GOAL_RIGHT_HEIGHT   1000

#define GOAL_LEFT_POS_X    50
#define GOAL_LEFT_POS_Y    300
#define GOAL_LEFT_WIDTH    10
#define GOAL_LEFT_HEIGHT   1000

#define WALL_TOP_POS_X    425
#define WALL_TOP_POS_Y    600
#define WALL_TOP_WIDTH    1000
#define WALL_TOP_HEIGHT   10

#define WALL_BOTTOM_POS_X    425
#define WALL_BOTTOM_POS_Y    0
#define WALL_BOTTOM_WIDTH    1000
#define WALL_BOTTOM_HEIGHT   10

#define BALL_POS_X            425
#define BALL_POS_Y            300
#define BALL_RADIUS            15.0f
#define BALL_SPHERE_SEGS    128

/*
struct CollisionEvent {
    b2Body* a;
    b2Body* b;
};
 */

@interface CBox2D : NSObject 

-(void) HelloWorld; // Basic Hello World! example from Box2D

-(void) LaunchBall;                 // launch the ball
-(void) MovePaddleRight:(float)amount;
-(void) MovePaddleLeft:(float)amount;
-(int) GetPlayerOneScore;
-(int) GetPlayerTwoScore;
-(void) Update:(float)elapsedTime;  // update the Box2D engine
//-(void) RegisterHit:(CollisionEvent)event;
-(void *)GetObjectPositions;        // Get the positions of the ball and brick

@end

#endif
