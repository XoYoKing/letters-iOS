//
//  SendViewController.h
//  crushes
//
//  Created by Seth Hayward on 12/6/12.
//  Copyright (c) 2012 Seth Hayward. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SendViewController : UIViewController
{
    __weak IBOutlet UITextView *messageText;
    __weak IBOutlet UIButton *sendButton;    
}

@end
