//
//  Copyright © Borna Noureddin. All rights reserved.
//

#include <Box2D/Box2D.h>
#include "CBox2D.h"
#include <stdio.h>
#include <map>

// Some Box2D engine paremeters
const float MAX_TIMESTEP = 1.0f/60.0f;
const int NUM_VEL_ITERATIONS = 10;
const int NUM_POS_ITERATIONS = 3;

#pragma mark - Box2D contact listener class

struct CollisionEvent {
    b2Body* a;
    b2Body* b;
};

// This C++ class is used to handle collisions
class CContactListener : public b2ContactListener
{
public:
    void BeginContact(b2Contact* contact) {};
    void EndContact(b2Contact* contact) {};
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
    {
        b2WorldManifold worldManifold;
        contact->GetWorldManifold(&worldManifold);
        b2PointState state1[2], state2[2];
        b2GetPointStates(state1, state2, oldManifold, contact->GetManifold());
        if (state2[0] == b2_addState)
        {
            // Use contact->GetFixtureA()->GetBody() to get the body
            b2Body* bodyA = contact->GetFixtureA()->GetBody();
            b2Body* bodyB = contact->GetFixtureB()->GetBody();
            CBox2D *parentObj = (__bridge CBox2D *)(bodyA->GetUserData());
            
            
            CollisionEvent event;
            event.a = bodyA;
            event.b = bodyB;
            
            
            // Call RegisterHit (assume CBox2D object is in user data)
            // [parentObj RegisterHit: event];    // assumes RegisterHit is a callback function to register collision
            RegisterHit(parentObj, event);
            
        }
    }
    void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {};
    void RegisterHit(CBox2D *parent, CollisionEvent event){
        
        auto objList = static_cast<std::map<const char *, b2Body*> *>([parent GetObjectB2Bodies]);
        
        // b2Body *theBall = (*objList).find("ball")["ball"];
        b2Body **theBall = (((*objList).find("ball") == (*objList).end()) ? nullptr : &(*objList)["ball"]);
        
        b2Body **thePaddleOne = (((*objList).find("paddleOne") == (*objList).end()) ? nullptr : &(*objList)["paddleOne"]);
        
        b2Body **thePaddleTwo = (((*objList).find("paddleTwo") == (*objList).end()) ? nullptr : &(*objList)["paddleTwo"]);
        
        b2Body **theGoalRight = (((*objList).find("goalRight") == (*objList).end()) ? nullptr : &(*objList)["goalRight"]);
        
        b2Body **theGoalLeft = (((*objList).find("goalLeft") == (*objList).end()) ? nullptr : &(*objList)["goalLeft"]);
        
        b2Body **theWallTop = (((*objList).find("wallTop") == (*objList).end()) ? nullptr : &(*objList)["wallTop"]);
        
        b2Body **theWallBottom = (((*objList).find("wallBottom") == (*objList).end()) ? nullptr : &(*objList)["wallBottom"]);
        
        if (event.b == *theBall) {
            if (event.a == *thePaddleOne) {
                printf("Paddle One\n");
            }
            if (event.a == *thePaddleTwo) {
                printf("Paddle Two\n");
            }
            if (event.a == *theGoalRight) {
                printf("Goal Right\n");
                parent.PlayerOneScored;
            }
            if (event.a == *theGoalLeft) {
                printf("Goal Left\n");
                parent.PlayerTwoScored;
            }
            if (event.a == *theWallTop) {
                printf("Wall Top\n");
            }
            if (event.a == *theWallBottom) {
                printf("Wall Bottom\n");
            }
        }
    }
};


#pragma mark - CBox2D

@interface CBox2D ()
{
    // Box2D-specific objects
    b2Vec2 *gravity;
    b2World *world;
    b2BodyDef *groundBodyDef;
    b2Body *groundBody;
    b2PolygonShape *groundBox;
    
    b2Body *thePaddleOne, *thePaddleTwo, *theBall, *theGoalRight, *theGoalLeft, *theWallTop, *theWallBottom;
    CContactListener *contactListener;
    float totalElapsedTime;
    
    int playerOneScore;
    int playerTwoScore;
    
    float paddleSpeed;
    
    // You will also need some extra variables here for the logic
    bool ballHitGoalRight;
    bool ballHitGoalLeft;
    bool ballLaunched;
}
@end

@implementation CBox2D

- (int)GetPlayerOneScore{
    return playerOneScore;
}

-(int)GetPlayerTwoScore{
    return playerTwoScore;
}

-(void)PlayerOneScored {
    ballHitGoalRight = true;
}

-(void)PlayerTwoScored {
    ballHitGoalLeft = true;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Initialize Box2D
        gravity = new b2Vec2(0.0f, -0.0f);
        world = new b2World(*gravity);
        
        // For HelloWorld
        groundBodyDef = NULL;
        groundBody = NULL;
        groundBox = NULL;

        // For brick & ball sample
        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        // Set Paddle Speed
        paddleSpeed = 10000.0f;
        
        // Set up the brick and ball objects for Box2D
        // Paddle One
        b2BodyDef thePaddleOneBodyDef;
        thePaddleOneBodyDef.type = b2_kinematicBody;
        thePaddleOneBodyDef.position.Set(PADDLE_LEFT_POS_X, PADDLE_LEFT_POS_Y);
        thePaddleOne = world->CreateBody(&thePaddleOneBodyDef);
        if (thePaddleOne)
        {
            thePaddleOne->SetUserData((__bridge void *)self);
            thePaddleOne->SetAwake(true);
            b2PolygonShape dynamicBox;
            dynamicBox.SetAsBox(PADDLE_LEFT_WIDTH/2, PADDLE_LEFT_HEIGHT/2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 1.0f;
            thePaddleOne->CreateFixture(&fixtureDef);
        }
        
        // Paddle Two
        b2BodyDef thePaddleTwoBodyDef;
        thePaddleTwoBodyDef.type = b2_kinematicBody;
        thePaddleTwoBodyDef.position.Set(PADDLE_RIGHT_POS_X, PADDLE_RIGHT_POS_Y);
        thePaddleTwo = world->CreateBody(&thePaddleTwoBodyDef);
        if (thePaddleTwo)
        {
            thePaddleTwo->SetUserData((__bridge void *)self);
            thePaddleTwo->SetAwake(true);
            b2PolygonShape dynamicBox;
            dynamicBox.SetAsBox(PADDLE_RIGHT_WIDTH/2, PADDLE_RIGHT_HEIGHT/2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 1.0f;
            thePaddleTwo->CreateFixture(&fixtureDef);
        }
        
        // Goal Right
        b2BodyDef theGoalRightBodyDef;
        theGoalRightBodyDef.type = b2_staticBody;
        theGoalRightBodyDef.position.Set(GOAL_RIGHT_POS_X, GOAL_RIGHT_POS_Y);
        theGoalRight = world->CreateBody(&theGoalRightBodyDef);
        if (theGoalRight)
        {
            theGoalRight->SetUserData((__bridge void *)self);
            theGoalRight->SetAwake(true);
            b2PolygonShape staticBox;
            staticBox.SetAsBox(GOAL_RIGHT_WIDTH/2, GOAL_RIGHT_HEIGHT/2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &staticBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 1.0f;
            theGoalRight->CreateFixture(&fixtureDef);
        }
        
        // Goal Left
        b2BodyDef theGoalLeftBodyDef;
        theGoalLeftBodyDef.type = b2_staticBody;
        theGoalLeftBodyDef.position.Set(GOAL_LEFT_POS_X, GOAL_LEFT_POS_Y);
        theGoalLeft = world->CreateBody(&theGoalLeftBodyDef);
        if (theGoalLeft)
        {
            theGoalLeft->SetUserData((__bridge void *)self);
            theGoalLeft->SetAwake(true);
            b2PolygonShape staticBox;
            staticBox.SetAsBox(GOAL_LEFT_WIDTH/2, GOAL_LEFT_HEIGHT/2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &staticBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 1.0f;
            theGoalLeft->CreateFixture(&fixtureDef);
        }
        
        // Wall Top
        b2BodyDef theWallTopBodyDef;
        theWallTopBodyDef.type = b2_staticBody;
        theWallTopBodyDef.position.Set(WALL_TOP_POS_X, WALL_TOP_POS_Y);
        theWallTop = world->CreateBody(&theWallTopBodyDef);
        if (theWallTop)
        {
            theWallTop->SetUserData((__bridge void *)self);
            theWallTop->SetAwake(true);
            b2PolygonShape staticBox;
            staticBox.SetAsBox(WALL_TOP_WIDTH/2, WALL_TOP_HEIGHT/2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &staticBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 1.0f;
            theWallTop->CreateFixture(&fixtureDef);
        }
        
        // Wall Bottom
        b2BodyDef theWallBottomBodyDef;
        theWallBottomBodyDef.type = b2_staticBody;
        theWallBottomBodyDef.position.Set(WALL_BOTTOM_POS_X, WALL_BOTTOM_POS_Y);
        theWallBottom = world->CreateBody(&theWallBottomBodyDef);
        if (theWallBottom)
        {
            theWallBottom->SetUserData((__bridge void *)self);
            theWallBottom->SetAwake(true);
            b2PolygonShape staticBox;
            staticBox.SetAsBox(WALL_BOTTOM_WIDTH/2, WALL_BOTTOM_HEIGHT/2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &staticBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 1.0f;
            theWallBottom->CreateFixture(&fixtureDef);
        }
        
        // Ball
        b2BodyDef ballBodyDef;
        ballBodyDef.type = b2_dynamicBody;
        ballBodyDef.position.Set(BALL_POS_X, BALL_POS_Y);
        theBall = world->CreateBody(&ballBodyDef);
        if (theBall)
        {
            theBall->SetUserData((__bridge void *)self);
            theBall->SetAwake(false);
            b2CircleShape circle;
            circle.m_p.Set(0, 0);
            circle.m_radius = BALL_RADIUS;
            b2FixtureDef circleFixtureDef;
            circleFixtureDef.shape = &circle;
            circleFixtureDef.density = 1.0f;
            circleFixtureDef.friction = 0.3f;
            circleFixtureDef.restitution = 10.0f;
            theBall->CreateFixture(&circleFixtureDef);
        }
        totalElapsedTime = 0;
        ballHitGoalLeft = false;
        ballHitGoalRight = false;
        ballLaunched = false;
    }
    return self;
}
- (void)dealloc
{
    if (gravity) delete gravity;
    if (world) delete world;
    if (groundBodyDef) delete groundBodyDef;
    if (groundBox) delete groundBox;
    if (contactListener) delete contactListener;
}

-(void)Update:(float)elapsedTime
{
    // Check here if we need to launch the ball
    //  and if so, use ApplyLinearImpulse() and SetActive(true)
    if (ballLaunched)
    {
        float min = 10000.0f;
        float max = 50000.0f;
        float diff = min - max;
        float yVelocity = (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + min;
        float xVelocity = max;
        
        b2Vec2 startVelocity = b2Vec2(xVelocity, yVelocity);
        theBall->ApplyLinearImpulse(startVelocity, theBall->GetPosition(), true);
        theBall->SetActive(true);

        NSLog(@"Applying impulse %f %f to ball\n", xVelocity, yVelocity);
        ballLaunched = false;
    }
    
    // Check if it is time yet to drop the brick, and if so
    //  call SetAwake()
    totalElapsedTime += elapsedTime;
    
    if (ballHitGoalLeft) {
        // Add One to Score
        playerTwoScore += 1;
        // Reset
        theBall->SetLinearVelocity(b2Vec2(0, 0));
        theBall->SetAngularVelocity(0);
        theBall->SetTransform(b2Vec2(BALL_POS_X, BALL_POS_Y), 0);
        theBall->SetActive(false);
        // ballLaunched = true;
        ballHitGoalLeft = false;
    }

    if (ballHitGoalRight) {
        // Add One to Score
        playerOneScore += 1;
        // Reset
        theBall->SetLinearVelocity(b2Vec2(0, 0));
        theBall->SetAngularVelocity(0);
        theBall->SetTransform(b2Vec2(BALL_POS_X, BALL_POS_Y), 0);
        theBall->SetActive(false);
        // ballLaunched = true;
        ballHitGoalRight = false;
    }
    
    if (world)
    {
        while (elapsedTime >= MAX_TIMESTEP)
        {
            world->Step(MAX_TIMESTEP, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
            elapsedTime -= MAX_TIMESTEP;
        }
        
        if (elapsedTime > 0.0f)
        {
            world->Step(elapsedTime, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
        }
    }
}
 
-(void)LaunchBall
{
    printf("Ball Launched\n");
    // Set some flag here for processing later...
    ballLaunched = true;
}

-(void)MovePaddleLeft:(float)amount{
    // printf("Moving Left Paddle\n");
    if (thePaddleOne) {
        thePaddleOne->SetLinearVelocity(b2Vec2(0, amount * paddleSpeed));
    }}

-(void)MovePaddleRight:(float)amount{
    // printf("Moving Right Paddle\n");
    if (thePaddleTwo) {
        thePaddleTwo->SetLinearVelocity(b2Vec2(0, amount * paddleSpeed));
    }
}

-(void *)GetObjectPositions
{
    auto *objPosList = new std::map<const char *,b2Vec2>;
    if (theBall)
        (*objPosList)["ball"] = theBall->GetPosition();
    if (thePaddleOne)
        (*objPosList)["paddleOne"] = thePaddleOne->GetPosition();
    if (thePaddleTwo)
        (*objPosList)["paddleTwo"] = thePaddleTwo->GetPosition();
    if (theGoalRight)
        (*objPosList)["goalRight"] = theGoalRight->GetPosition();
    if (theGoalLeft)
        (*objPosList)["goalLeft"] = theGoalLeft->GetPosition();
    if (theWallTop)
        (*objPosList)["wallTop"] = theWallTop->GetPosition();
    if (theWallBottom)
        (*objPosList)["wallBottom"] = theWallBottom->GetPosition();
    return reinterpret_cast<void *>(objPosList);
}

-(void *)GetObjectB2Bodies{
    auto *objList = new std::map<const char *,b2Body*>;
    if (theBall)
        (*objList)["ball"] = theBall;
    if (thePaddleOne)
        (*objList)["paddleOne"] = thePaddleOne;
    if (thePaddleTwo)
        (*objList)["paddleTwo"] = thePaddleTwo;
    if (theGoalRight)
        (*objList)["goalRight"] = theGoalRight;
    if (theGoalLeft)
        (*objList)["goalLeft"] = theGoalLeft;
    if (theWallTop)
        (*objList)["wallTop"] = theWallTop;
    if (theWallBottom)
        (*objList)["wallBottom"] = theWallBottom;
    return reinterpret_cast<void *>(objList);
}

-(void)HelloWorld
{
    groundBodyDef = new b2BodyDef;
    groundBodyDef->position.Set(0.0f, -10.0f);
    groundBody = world->CreateBody(groundBodyDef);
    groundBox = new b2PolygonShape;
    groundBox->SetAsBox(50.0f, 10.0f);
    
    groundBody->CreateFixture(groundBox, 0.0f);
    
    // Define the dynamic body. We set its position and call the body factory.
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position.Set(0.0f, 4.0f);
    b2Body* body = world->CreateBody(&bodyDef);
    
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox;
    dynamicBox.SetAsBox(1.0f, 1.0f);
    
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &dynamicBox;
    
    // Set the box density to be non-zero, so it will be dynamic.
    fixtureDef.density = 1.0f;
    
    // Override the default friction.
    fixtureDef.friction = 0.3f;
    
    // Add the shape to the body.
    body->CreateFixture(&fixtureDef);
    
    // Prepare for simulation. Typically we use a time step of 1/60 of a
    // second (60Hz) and 10 iterations. This provides a high quality simulation
    // in most game scenarios.
    float32 timeStep = 1.0f / 60.0f;
    int32 velocityIterations = 6;
    int32 positionIterations = 2;
    
    // This is our little game loop.
    for (int32 i = 0; i < 60; ++i)
    {
        // Instruct the world to perform a single step of simulation.
        // It is generally best to keep the time step and iterations fixed.
        world->Step(timeStep, velocityIterations, positionIterations);
        
        // Now print the position and angle of the body.
        b2Vec2 position = body->GetPosition();
        float32 angle = body->GetAngle();
        
        printf("%4.2f %4.2f %4.2f\n", position.x, position.y, angle);
    }
}

@end
