//
//  SPTextureAtlas.m
//  Sparrow
//
//  Created by Daniel Sperl on 27.06.09.
//  Copyright 2011 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTextureAtlas.h"
#import "SPMacros.h"
#import "SPTexture.h"
#import "SPSubTexture.h"
#import "SPGLTexture.h"
#import "SPRectangle.h"
#import "SPUtils.h"
#import "SparrowClass.h"

// --- private interface ---------------------------------------------------------------------------

@interface SPTextureAtlas()

- (void)parseAtlasXml:(NSString*)path;

@end

// --- class implementation ------------------------------------------------------------------------

@implementation SPTextureAtlas
{
    SPTexture *_atlasTexture;
    NSString *_path;
    NSMutableDictionary *_textureRegions;
    NSMutableDictionary *_textureFrames;
}

- (id)initWithContentsOfFile:(NSString *)path texture:(SPTexture *)texture
{
    if ((self = [super init]))
    {
        _textureRegions = [[NSMutableDictionary alloc] init];
        _textureFrames  = [[NSMutableDictionary alloc] init];
        _atlasTexture = texture;
        [self parseAtlasXml:path];
    }
    return self;    
}

- (id)initWithContentsOfFile:(NSString *)path
{
    return [self initWithContentsOfFile:path texture:nil];
}

- (id)initWithTexture:(SPTexture *)texture
{
    return [self initWithContentsOfFile:nil texture:(SPTexture *)texture];
}

- (id)init
{
    return [self initWithContentsOfFile:nil texture:nil];
}

- (void)parseAtlasXml:(NSString *)path
{
    if (!path) return;

    float scaleFactor = Sparrow.contentScaleFactor;
    _path = [SPUtils absolutePathToFile:path withScaleFactor:scaleFactor];    
    if (!_path) [NSException raise:SP_EXC_FILE_NOT_FOUND format:@"file not found: %@", path];
    
    @autoreleasepool
    {
        NSData *xmlData = [[NSData alloc] initWithContentsOfFile:_path];
        NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:xmlData];
        
        xmlParser.delegate = self;    
        BOOL success = [xmlParser parse];
        
        if (!success)    
            [NSException raise:SP_EXC_FILE_INVALID 
                        format:@"could not parse texture atlas %@. Error code: %d, domain: %@", 
                               path, xmlParser.parserError.code, xmlParser.parserError.domain];
    }
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
                                        namespaceURI:(NSString *)namespaceURI 
                                       qualifiedName:(NSString *)qName 
                                          attributes:(NSDictionary *)attributeDict 
{
    if ([elementName isEqualToString:@"SubTexture"])
    {
        float scale = _atlasTexture.scale;
        
        NSString *name = attributeDict[@"name"];
        SPRectangle *frame = nil;
        
        float x = [attributeDict[@"x"] floatValue] / scale;
        float y = [attributeDict[@"y"] floatValue] / scale;
        float width = [attributeDict[@"width"] floatValue] / scale;
        float height = [attributeDict[@"height"] floatValue] / scale;
        float frameX = [attributeDict[@"frameX"] floatValue] / scale;
        float frameY = [attributeDict[@"frameY"] floatValue] / scale;
        float frameWidth = [attributeDict[@"frameWidth"] floatValue] / scale;
        float frameHeight = [attributeDict[@"frameHeight"] floatValue] / scale;
        
        if (frameWidth && frameHeight)
            frame = [SPRectangle rectangleWithX:frameX y:frameY width:frameWidth height:frameHeight];
        
        [self addRegion:[SPRectangle rectangleWithX:x y:y width:width height:height] 
               withName:name frame:frame];
    }
    else if ([elementName isEqualToString:@"TextureAtlas"] && !_atlasTexture)
    {
        // load atlas texture
        NSString *filename = [attributeDict valueForKey:@"imagePath"];        
        NSString *folder = [_path stringByDeletingLastPathComponent];
        NSString *absolutePath = [folder stringByAppendingPathComponent:filename];
        _atlasTexture = [[SPTexture alloc] initWithContentsOfFile:absolutePath];
    }
}

- (int)count
{
    return [_textureRegions count];
}

- (SPTexture *)textureByName:(NSString *)name
{
    SPRectangle *frame  = _textureFrames[name];
    SPRectangle *region = _textureRegions[name];
    
    if (region) return [[SPTexture alloc] initWithRegion:region frame:frame ofTexture:_atlasTexture];
    else        return nil;
}

- (NSArray *)texturesStartingWith:(NSString *)name
{
    NSMutableArray *textureNames = [[NSMutableArray alloc] init];
    
    for (NSString *textureName in _textureRegions)
        if ([textureName rangeOfString:name].location == 0)
            [textureNames addObject:textureName];
    
    // note: when switching to iOS 4, 'localizedStandardCompare:' would be preferable    
    [textureNames sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSMutableArray *textures = [NSMutableArray arrayWithCapacity:textureNames.count];
    for (NSString *textureName in textureNames)
        [textures addObject:[self textureByName:textureName]];
    
    return textures;
}

- (void)addRegion:(SPRectangle *)region withName:(NSString *)name
{
    [self addRegion:region withName:name frame:nil];
}

- (void)addRegion:(SPRectangle *)region withName:(NSString *)name frame:(SPRectangle *)frame
{
    _textureRegions[name] = region;    
    if (frame) _textureFrames[name] = frame;
}

- (void)removeRegion:(NSString *)name
{
    [_textureRegions removeObjectForKey:name];
    [_textureFrames  removeObjectForKey:name];
}

+ (id)atlasWithContentsOfFile:(NSString *)path
{
    return [[self alloc] initWithContentsOfFile:path];
}

@end
