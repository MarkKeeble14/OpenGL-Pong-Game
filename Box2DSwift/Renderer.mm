//
//  Copyright © Borna Noureddin. All rights reserved.
//

#import "Renderer.h"
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include <chrono>
#include "GLESRenderer.hpp"
#include <Box2D/Box2D.h>
#include <map>

// Debug flag to dump ball/brick updated coordinates to console
//#define LOG_TO_CONSOLE

// Simple 2D rendering, so only need MVP matrix
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Two vertex attribute
enum
{
    ATTRIB_POS,
    ATTRIB_COL,
    NUM_ATTRIBUTES
};

// Used to make the VBO code more readable
#define BUFFER_OFFSET(i) ((char *)NULL + (i))


@interface Renderer () {
    GLKView *theView;
    GLESRenderer glesRenderer;
    GLuint programObject;
    std::chrono::time_point<std::chrono::steady_clock> lastTime;    // used to calculated elapsed time

    GLuint paddleOneVertexArray, paddleTwoVertexArray, ballVertexArray, goalRightVertexArray, goalLeftVertexArray;   // vertex arrays for paddles and ball
    int numPaddleOneVerts, numPaddleTwoVerts, numBallVerts, numGoalRightVerts, numGoalLeftVerts;
    GLKMatrix4 modelViewProjectionMatrix;   // model-view-projection matrix
}

@end

@implementation Renderer

@synthesize box2d;

- (void)dealloc
{
    glDeleteProgram(programObject);
}

- (void)loadModels
{
    [box2d HelloWorld]; // Just a simple HelloWorld test for Box2D. Can be removed.
}

- (void)setup:(GLKView *)view
{
    // Set up OpenGL ES
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!view.context) {
        NSLog(@"Failed to create ES context");
    }
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    theView = view;
    [EAGLContext setCurrentContext:view.context];
    
    // Load shaders
    if (![self setupShaders])
        return;

    // Set background colours and initialize timer
    glClearColor ( 0.0f, 0.0f, 0.0f, 0.0f );
    glEnable(GL_DEPTH_TEST);
    lastTime = std::chrono::steady_clock::now();

    // Initialize Box2D
    box2d = [[CBox2D alloc] init];
}

- (void)update
{
    // Calculate elapsed time and update Box2D
    auto currentTime = std::chrono::steady_clock::now();
    auto elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime - lastTime).count();
    lastTime = currentTime;
    [box2d Update:elapsedTime/1000.0f];

    // Get the ball and brick objects from Box2D
    auto objPosList = static_cast<std::map<const char *, b2Vec2> *>([box2d GetObjectPositions]);
    b2Vec2 *theBall = (((*objPosList).find("ball") == (*objPosList).end()) ? nullptr : &(*objPosList)["ball"]);
    
    // Paddles
    b2Vec2 *thePaddleOne = (((*objPosList).find("paddleOne") == (*objPosList).end()) ? nullptr : &(*objPosList)["paddleOne"]);
    b2Vec2 *thePaddleTwo = (((*objPosList).find("paddleTwo") == (*objPosList).end()) ? nullptr : &(*objPosList)["paddleTwo"]);
    
    // Goals
    b2Vec2 *theGoalRight = (((*objPosList).find("goalRight") == (*objPosList).end()) ? nullptr : &(*objPosList)["goalRight"]);
    b2Vec2 *theGoalLeft = (((*objPosList).find("goalLeft") == (*objPosList).end()) ? nullptr : &(*objPosList)["goalLeft"]);
    
    // Walls
    // b2Vec2 *thePaddleOne = (((*objPosList).find("paddleOne") == (*objPosList).end()) ? nullptr : &(*objPosList)["paddleOne"]);
    // b2Vec2 *thePaddleTwo = (((*objPosList).find("paddleTwo") == (*objPosList).end()) ? nullptr : &(*objPosList)["paddleTwo"]);
    
    if (thePaddleOne)
    {
        // Set up VAO/VBO for brick
        glGenVertexArrays(1, &paddleOneVertexArray);
        glBindVertexArray(paddleOneVertexArray);
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        
        // VBO for vertex positions
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[18];    // 2 triangles x 3 vertices/triangle x 3 coords (x,y,z) per vertex
        int k = 0;
        numPaddleOneVerts = 0;
        vertPos[k++] = thePaddleOne->x - PADDLE_LEFT_WIDTH/2;
        vertPos[k++] = thePaddleOne->y + PADDLE_LEFT_HEIGHT/2;
        vertPos[k++] = 10;  // z-value is always set to same value since 2D
        numPaddleOneVerts++;
        vertPos[k++] = thePaddleOne->x + PADDLE_LEFT_WIDTH/2;
        vertPos[k++] = thePaddleOne->y + PADDLE_LEFT_HEIGHT/2;
        vertPos[k++] = 10;
        numPaddleOneVerts++;
        vertPos[k++] = thePaddleOne->x + PADDLE_LEFT_WIDTH/2;
        vertPos[k++] = thePaddleOne->y - PADDLE_LEFT_HEIGHT/2;
        vertPos[k++] = 10;
        numPaddleOneVerts++;
        vertPos[k++] = thePaddleOne->x - PADDLE_LEFT_WIDTH/2;
        vertPos[k++] = thePaddleOne->y + PADDLE_LEFT_HEIGHT/2;
        vertPos[k++] = 10;
        numPaddleOneVerts++;
        vertPos[k++] = thePaddleOne->x + PADDLE_LEFT_WIDTH/2;
        vertPos[k++] = thePaddleOne->y - PADDLE_LEFT_HEIGHT/2;
        vertPos[k++] = 10;
        numPaddleOneVerts++;
        vertPos[k++] = thePaddleOne->x - PADDLE_LEFT_WIDTH/2;
        vertPos[k++] = thePaddleOne->y - PADDLE_LEFT_HEIGHT/2;
        vertPos[k++] = 10;
        numPaddleOneVerts++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_POS);
        glVertexAttribPointer(ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // VBO for vertex colours
        GLfloat vertCol[numPaddleOneVerts*3];
        for (k=0; k<numPaddleOneVerts*3; k+=3)
        {
            vertCol[k] = 1.0f;
            vertCol[k+1] = 0.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_COL);
        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindVertexArray(0);
    }
    
    if (thePaddleTwo)
    {
        // Set up VAO/VBO for brick
        glGenVertexArrays(1, &paddleTwoVertexArray);
        glBindVertexArray(paddleTwoVertexArray);
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        
        // VBO for vertex positions
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[18];    // 2 triangles x 3 vertices/triangle x 3 coords (x,y,z) per vertex
        int k = 0;
        numPaddleTwoVerts = 0;
        vertPos[k++] = thePaddleTwo->x - PADDLE_RIGHT_WIDTH/2;
        vertPos[k++] = thePaddleTwo->y + PADDLE_RIGHT_HEIGHT/2;
        vertPos[k++] = 10;  // z-value is always set to same value since 2D
        numPaddleTwoVerts++;
        vertPos[k++] = thePaddleTwo->x + PADDLE_RIGHT_WIDTH/2;
        vertPos[k++] = thePaddleTwo->y + PADDLE_RIGHT_HEIGHT/2;
        vertPos[k++] = 10;
        numPaddleTwoVerts++;
        vertPos[k++] = thePaddleTwo->x + PADDLE_RIGHT_WIDTH/2;
        vertPos[k++] = thePaddleTwo->y - PADDLE_RIGHT_HEIGHT/2;
        vertPos[k++] = 10;
        numPaddleTwoVerts++;
        vertPos[k++] = thePaddleTwo->x - PADDLE_RIGHT_WIDTH/2;
        vertPos[k++] = thePaddleTwo->y + PADDLE_RIGHT_HEIGHT/2;
        vertPos[k++] = 10;
        numPaddleTwoVerts++;
        vertPos[k++] = thePaddleTwo->x + PADDLE_RIGHT_WIDTH/2;
        vertPos[k++] = thePaddleTwo->y - PADDLE_RIGHT_HEIGHT/2;
        vertPos[k++] = 10;
        numPaddleTwoVerts++;
        vertPos[k++] = thePaddleTwo->x - PADDLE_RIGHT_WIDTH/2;
        vertPos[k++] = thePaddleTwo->y - PADDLE_RIGHT_HEIGHT/2;
        vertPos[k++] = 10;
        numPaddleTwoVerts++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_POS);
        glVertexAttribPointer(ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // VBO for vertex colours
        GLfloat vertCol[numPaddleTwoVerts*3];
        for (k=0; k<numPaddleTwoVerts*3; k+=3)
        {
            vertCol[k] = 1.0f;
            vertCol[k+1] = 0.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_COL);
        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindVertexArray(0);
    }
     
    if (theGoalRight)
    {
        // Set up VAO/VBO for brick
        glGenVertexArrays(1, &goalRightVertexArray);
        glBindVertexArray(goalRightVertexArray);
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        
        // VBO for vertex positions
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[18];    // 2 triangles x 3 vertices/triangle x 3 coords (x,y,z) per vertex
        int k = 0;
        numGoalRightVerts = 0;
        vertPos[k++] = theGoalRight->x - GOAL_RIGHT_WIDTH/2;
        vertPos[k++] = theGoalRight->y + GOAL_RIGHT_HEIGHT/2;
        vertPos[k++] = 10;  // z-value is always set to same value since 2D
        numGoalRightVerts++;
        vertPos[k++] = theGoalRight->x + GOAL_RIGHT_WIDTH/2;
        vertPos[k++] = theGoalRight->y + GOAL_RIGHT_HEIGHT/2;
        vertPos[k++] = 10;
        numGoalRightVerts++;
        vertPos[k++] = theGoalRight->x + GOAL_RIGHT_WIDTH/2;
        vertPos[k++] = theGoalRight->y - GOAL_RIGHT_HEIGHT/2;
        vertPos[k++] = 10;
        numGoalRightVerts++;
        vertPos[k++] = theGoalRight->x - GOAL_RIGHT_WIDTH/2;
        vertPos[k++] = theGoalRight->y + GOAL_RIGHT_HEIGHT/2;
        vertPos[k++] = 10;
        numGoalRightVerts++;
        vertPos[k++] = theGoalRight->x + GOAL_RIGHT_WIDTH/2;
        vertPos[k++] = theGoalRight->y - GOAL_RIGHT_HEIGHT/2;
        vertPos[k++] = 10;
        numGoalRightVerts++;
        vertPos[k++] = theGoalRight->x - GOAL_RIGHT_WIDTH/2;
        vertPos[k++] = theGoalRight->y - GOAL_RIGHT_HEIGHT/2;
        vertPos[k++] = 10;
        numGoalRightVerts++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_POS);
        glVertexAttribPointer(ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // VBO for vertex colours
        GLfloat vertCol[numGoalRightVerts*3];
        for (k=0; k<numGoalRightVerts*3; k+=3)
        {
            vertCol[k] = 1.0f;
            vertCol[k+1] = 0.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_COL);
        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindVertexArray(0);
    }
    
    if (theGoalLeft)
    {
        // Set up VAO/VBO for brick
        glGenVertexArrays(1, &goalLeftVertexArray);
        glBindVertexArray(goalLeftVertexArray);
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        
        // VBO for vertex positions
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[18];    // 2 triangles x 3 vertices/triangle x 3 coords (x,y,z) per vertex
        int k = 0;
        numGoalLeftVerts = 0;
        vertPos[k++] = theGoalLeft->x - GOAL_LEFT_WIDTH/2;
        vertPos[k++] = theGoalLeft->y + GOAL_LEFT_HEIGHT/2;
        vertPos[k++] = 10;  // z-value is always set to same value since 2D
        numGoalLeftVerts++;
        vertPos[k++] = theGoalLeft->x + GOAL_LEFT_WIDTH/2;
        vertPos[k++] = theGoalLeft->y + GOAL_LEFT_HEIGHT/2;
        vertPos[k++] = 10;
        numGoalLeftVerts++;
        vertPos[k++] = theGoalLeft->x + GOAL_LEFT_WIDTH/2;
        vertPos[k++] = theGoalLeft->y - GOAL_LEFT_HEIGHT/2;
        vertPos[k++] = 10;
        numGoalLeftVerts++;
        vertPos[k++] = theGoalLeft->x - GOAL_LEFT_WIDTH/2;
        vertPos[k++] = theGoalLeft->y + GOAL_LEFT_HEIGHT/2;
        vertPos[k++] = 10;
        numGoalLeftVerts++;
        vertPos[k++] = theGoalLeft->x + GOAL_LEFT_WIDTH/2;
        vertPos[k++] = theGoalLeft->y - GOAL_LEFT_HEIGHT/2;
        vertPos[k++] = 10;
        numGoalLeftVerts++;
        vertPos[k++] = theGoalLeft->x - GOAL_LEFT_WIDTH/2;
        vertPos[k++] = theGoalLeft->y - GOAL_LEFT_HEIGHT/2;
        vertPos[k++] = 10;
        numGoalLeftVerts++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_POS);
        glVertexAttribPointer(ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // VBO for vertex colours
        GLfloat vertCol[numGoalLeftVerts*3];
        for (k=0; k<numGoalLeftVerts*3; k+=3)
        {
            vertCol[k] = 1.0f;
            vertCol[k+1] = 0.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_COL);
        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindVertexArray(0);
    }
    
    if (theBall)
    {
        // Set up VAO/VBO for brick
        glGenVertexArrays(1, &ballVertexArray);
        glBindVertexArray(ballVertexArray);
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        
        // VBO for vertex colours
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[3*(BALL_SPHERE_SEGS+2)];    // triangle fan, so need 3 coords for each vertex; need to close the sphere; and need the center of the sphere
        int k = 0;
        // Center of the sphere
        vertPos[k++] = theBall->x;
        vertPos[k++] = theBall->y;
        vertPos[k++] = 0;
        numBallVerts = 1;
        for (int n=0; n<=BALL_SPHERE_SEGS; n++)
        {
            float const t = 2*M_PI*(float)n/(float)BALL_SPHERE_SEGS;
            vertPos[k++] = theBall->x + M_PI * sin(t)*BALL_RADIUS;
            vertPos[k++] = theBall->y + cos(t)*BALL_RADIUS;
            vertPos[k++] = 0;
            numBallVerts++;
        }
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_POS);
        glVertexAttribPointer(ATTRIB_POS, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        // VBO for vertex colours
        GLfloat vertCol[numBallVerts*3];
        for (k=0; k<numBallVerts*3; k+=3)
        {
            vertCol[k] = 0.0f;
            vertCol[k+1] = 1.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);    // Send vertex data to VBO
        glEnableVertexAttribArray(ATTRIB_COL);
        glVertexAttribPointer(ATTRIB_COL, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));

        glBindVertexArray(0);
    }

    // For now assume simple ortho projection since it's only 2D
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, 800, 0, 600, -10, 100);    // note bounding box matches Box2D world
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
}

- (void)draw:(CGRect)drawRect;
{
    // Set up GL for draw calls
    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    glClear ( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glUseProgram ( programObject );

    // Pass along updated MVP matrix
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, modelViewProjectionMatrix.m);

    // Retrieve brick and ball positions from Box2D
    auto objPosList = static_cast<std::map<const char *, b2Vec2> *>([box2d GetObjectPositions]);
    b2Vec2 *theBall = (((*objPosList).find("ball") == (*objPosList).end()) ? nullptr : &(*objPosList)["ball"]);
    b2Vec2 *thePaddleOne = (((*objPosList).find("paddleOne") == (*objPosList).end()) ? nullptr : &(*objPosList)["paddleOne"]);
    b2Vec2 *thePaddleTwo = (((*objPosList).find("paddleTwo") == (*objPosList).end()) ? nullptr : &(*objPosList)["paddleTwo"]);
    b2Vec2 *theGoalRight = (((*objPosList).find("goalRight") == (*objPosList).end()) ? nullptr : &(*objPosList)["goalRight"]);
    b2Vec2 *theGoalLeft = (((*objPosList).find("goalLeft") == (*objPosList).end()) ? nullptr : &(*objPosList)["goalLeft"]);
    
#ifdef LOG_TO_CONSOLE
    if (theBall)
        printf("Ball: (%5.3f,%5.3f)\t", theBall->x, theBall->y);
    printf("\n");
#endif

    // Bind each vertex array and call glDrawArrays for each of the ball and brick
    glBindVertexArray(paddleOneVertexArray);
    if (thePaddleOne && numPaddleOneVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, numPaddleOneVerts);
    
    glBindVertexArray(paddleTwoVertexArray);
    if (thePaddleTwo && numPaddleTwoVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, numPaddleTwoVerts);
    
    glBindVertexArray(goalRightVertexArray);
    if (theGoalRight && numGoalRightVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, numGoalRightVerts);
    
    glBindVertexArray(goalLeftVertexArray);
    if (theGoalLeft && numGoalLeftVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, numGoalLeftVerts);
    
    glBindVertexArray(ballVertexArray);
    if (theBall && numBallVerts > 0)
        glDrawArrays(GL_TRIANGLE_FAN, 0, numBallVerts);
}

- (bool)setupShaders
{
    // Load shaders
    char *vShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.vsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.vsh"] pathExtension]] cStringUsingEncoding:1]);
    char *fShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.fsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.fsh"] pathExtension]] cStringUsingEncoding:1]);
    programObject = glesRenderer.LoadProgram(vShaderStr, fShaderStr);
    if (programObject == 0)
        return false;
    
    // Set up uniform variables
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(programObject, "modelViewProjectionMatrix");

    return true;
}

@end

