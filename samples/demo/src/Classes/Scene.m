//
//  Scene.m
//  Demo
//
//  Created by Sperl Daniel on 06.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Scene.h"

@implementation Scene
{
    SPButton *_backButton;
}

- (id)init
{
    if ((self = [super init]))
    {
        // create a button with the text "back" and display it at the bottom of the screen.
        SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_back.png"];
        
        _backButton = [[SPButton alloc] initWithUpState:buttonTexture text:@"back"];
        _backButton.x = CENTER_X - _backButton.width / 2.0f;
        _backButton.y = GAME_HEIGHT - _backButton.height + 1;
        [_backButton addEventListener:@selector(onBackButtonTriggered:) atObject:self 
                              forType:SP_EVENT_TYPE_TRIGGERED];
        [self addChild:_backButton];
    }
    return self;
}

- (void)onBackButtonTriggered:(SPEvent *)event
{
    [_backButton removeEventListenersAtObject:self forType:SP_EVENT_TYPE_TRIGGERED];
    [self dispatchEventWithType:EVENT_TYPE_SCENE_CLOSING bubbles:YES];
}

@end
