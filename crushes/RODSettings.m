//
//  RODSettings.m
//  crushes
//
//  Created by Seth Hayward on 8/19/13.
//  Copyright (c) 2013 Seth Hayward. All rights reserved.
//

#import "RODSettings.h"

@implementation RODSettings
@synthesize loginStatus, userName, password, sentLetters, chatName;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self) {
        [self setLoginStatus:[aDecoder decodeObjectForKey:@"loginStatus"]];
        [self setUserName:[aDecoder decodeObjectForKey:@"userName"]];
        [self setPassword:[aDecoder decodeObjectForKey:@"password"]];
        [self setSentLetters:[aDecoder decodeObjectForKey:@"sentLetters"]];
        [self setChatName:[aDecoder decodeObjectForKey:@"chatName"]];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:loginStatus forKey:@"loginStatus"];
    [aCoder encodeObject:userName forKey:@"userName"];
    [aCoder encodeObject:password forKey:@"password"];
    [aCoder encodeObject:self.sentLetters forKey:@"sentLetters"];
    [aCoder encodeObject:chatName forKey:@"chatName"];
}

@end
