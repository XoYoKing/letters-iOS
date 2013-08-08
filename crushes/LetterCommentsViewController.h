//
//  LetterCommentsViewController.h
//  crushes
//
//  Created by Seth Hayward on 8/6/13.
//  Copyright (c) 2013 Seth Hayward. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LetterCommentsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic) int letter_id;

-(void)loadLetterData;
-(void)redrawScroll;

@end
