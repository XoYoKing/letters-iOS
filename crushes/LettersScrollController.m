//
//  LettersScrollController.m
//  crushes
//
//  Created by Seth Hayward on 7/24/13.
//  Copyright (c) 2013 Seth Hayward. All rights reserved.
//

#import "LettersScrollController.h"
#import "LetterCommentsViewController.h"
#import "MMDrawerBarButtonItem.h"
#import "RODItemStore.h"
#import "RKFullLetter.h"
#import "ScrollViewItem.h"
#import "AppDelegate.h"
#import "PagerViewController.h"

@implementation LettersScrollController
@synthesize current_receive, loaded, letter_index;

- (id)init
{
    self = [super init];
    if(self) {
        
        UIBarButtonItem *button_refresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshOriginalPage)];
        [[self navigationItem] setRightBarButtonItem:button_refresh];
        
        MMDrawerBarButtonItem * leftDrawerButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(openDrawer:)];
        [self.navigationItem setLeftBarButtonItem:leftDrawerButton animated:YES];
        
        [[self navigationItem] setTitle:@"letters to crushes"];

        [[RODItemStore sharedStore] loadLettersByPage:1 level:0];
 
        [self.indicator startAnimating];
        
        [self.scrollView setDelegate:self];
        
        self.letter_index = 0;
        
        current_receive = 0;
        loaded = false;
        
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.testWebView setDelegate:self];    
}

-(void)loadLetterData
{
    
    NSLog(@"loadLetterData called.");
    
    int yOffset = 0;
    
    ScrollViewItem *scv;
    
    for(int i = 0; i < [[[RODItemStore sharedStore] allLetters] count]; i++) {
        
        RKFullLetter *full_letter = [[[RODItemStore sharedStore] allLetters] objectAtIndex:i];
        
        int letter_height = 0;
        
        if([full_letter.letterTags isEqualToString:@"1"]) {
            letter_height = [full_letter.letterCountry integerValue];
        } else {
            letter_height = 100;
        }
        
        scv = [[ScrollViewItem alloc] init];
        
        scv.current_index = i;
        // the height of the padding around the
        // heart button and the frame of the scrollviewitem is about 40px.
                
        scv.view.frame = CGRectMake(0, yOffset, self.view.bounds.size.width - 5, letter_height + 51);
        
        //[scv.webView setDelegate:self];
        
        [scv.webView loadHTMLString:full_letter.letterMessage baseURL:nil];
        
        [scv.labelComments setUserInteractionEnabled:true];
        
        UITapGestureRecognizer *tapComments = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedComments:)];
        [scv.labelComments addGestureRecognizer:tapComments];
        
        [scv.labelHearts setUserInteractionEnabled:true];
        
        UITapGestureRecognizer *tapHearts = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedHeart:)];
        [scv.labelHearts addGestureRecognizer:tapHearts];
        
        [scv.labelComments setTag:([full_letter.Id integerValue] * 100)];
        [scv.labelHearts setTag:([full_letter.Id integerValue] * 1000)];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        [formatter setDateStyle:NSDateFormatterFullStyle];
        
        //[formatter setDateFormat:@"yyyy mm dd"];
        [scv.labelDate setText:[formatter stringFromDate:[self getDateFromJSON:full_letter.letterPostDate]]];
        NSLog(@"Date: %@", full_letter.letterPostDate);
        [scv.webView.scrollView setScrollEnabled:false];
        
        // OMG JUST PUT A FUCKING UNDERLINE IN THE LABEL JESUS

        NSMutableAttributedString *attributeStringHearts = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ hearts", [full_letter.letterUp stringValue]]];

        NSMutableAttributedString *attributeStringComments = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ comments", [full_letter.letterComments stringValue]]];
        
        [attributeStringHearts addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:1] range:(NSRange){0,[attributeStringHearts length]}];
        [attributeStringComments addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:1] range:(NSRange){0,[attributeStringComments length]}];
        
        UIFont *normalFont = [UIFont systemFontOfSize:13];
        
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys: normalFont, NSFontAttributeName,
                               [UIColor colorWithRed:0/255.0
                                               green:51/255.0
                                                blue:255/255.0
                                               alpha:1.0], NSForegroundColorAttributeName, nil];
        
        [attributeStringHearts addAttributes:attrs range:(NSRange){0, [attributeStringHearts length]}];
        [attributeStringComments addAttributes:attrs range:(NSRange){0, [attributeStringComments length]}];
        
        [scv.labelHearts setAttributedText:attributeStringHearts];
        [scv.labelComments setAttributedText:attributeStringComments];
        
        
        // JESUS CHRIST
        
        if([full_letter.letterComments isEqualToNumber:[NSNumber numberWithInt:0]]) {
            [scv.labelComments  setHidden:true];
        }
        
        [scv setCurrent_letter:full_letter];
        
        yOffset = yOffset + (letter_height + 51);
                
        [self.scrollView addSubview:scv.view];
        
    }
    
    // now add the pager control
    PagerViewController *pager = [[PagerViewController alloc] init];
    pager.view.frame = CGRectMake(0, yOffset, self.view.bounds.size.width, pager.view.frame.size.height);
    
    if([[RODItemStore sharedStore] current_page] > 1) {
        [pager.buttonBack setHidden:false];
        [pager.buttonBack addTarget:self action:@selector(backButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        
    } else {
        [pager.buttonBack setHidden:true];
    }
    
    [pager.buttonNext addTarget:self action:@selector(nextButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.scrollView addSubview:pager.view];

    
    yOffset = yOffset + pager.view.frame.size.height;
    
    [self.scrollView setContentSize:CGSizeMake(self.view.bounds.size.width, yOffset)];
    
    // now try looping through and resetting everything?
    
}

- (void)clickedComments:(UITapGestureRecognizer *)tapGesture
{
    
    int letter_id = [tapGesture.view tag] / 100;
    
    LetterCommentsViewController *comments = [[LetterCommentsViewController alloc] init];
    comments.letter_id = letter_id;
    
    // now tell the web view to change the page
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate.navigationController pushViewController:comments animated:true];
        
}


-(void)clickedHeart:(UITapGestureRecognizer *)tapGesture;
{
    
    NSLog(@"Clicked heart.");
    
    int letter_id = [tapGesture.view tag] / 1000;
    
    NSURL *baseURL = [NSURL URLWithString:@"http://www.letterstocrushes.com"];
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    
    [client setDefaultHeader:@"Accept" value:RKMIMETypeJSON];
    
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:client];
    
    RKObjectMapping* responseObjectMapping = [RKObjectMapping mappingForClass:[RKFullLetter class]];
    [responseObjectMapping addAttributeMappingsFromDictionary:@{
     @"Id": @"Id",
     @"letterMessage": @"letterMessage",
     @"letterTags": @"letterTags",
     @"letterPostDate": @"letterPostDate",
     @"letterUp": @"letterUp",
     @"letterLevel": @"letterLevel",
     @"letterLanguage": @"letterLanguage",
     @"senderIP": @"senderIP",
     @"senderCountry": @"senderCountry",
     @"senderRegion": @"senderRegion",
     @"senderCity": @"senderCity",
     @"letterComments": @"letterComments"
     }];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:responseObjectMapping pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    NSString *real_url = [NSString stringWithFormat:@"http://www.letterstocrushes.com/home/vote/%d", letter_id];
    
    [objectManager addResponseDescriptor:responseDescriptor];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:real_url]];
    
    RKObjectRequestOperation *objectRequestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor] ];
    
    [objectRequestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        RKFullLetter *letter = mappingResult.array[0];
        NSLog(@"Voted on letter %@", letter.Id);
        
        [[RODItemStore sharedStore] updateLetterHearts:[NSNumber numberWithInt:letter_id] hearts: letter.letterUp];
        
        [self refreshOriginalPage];
        
        //[button setTitle:[NSString stringWithFormat:@"%@", letter.letterUp] forState:UIControlStateNormal];
        
    } failure: ^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Error voting: %@", error);
    }];
    
    [objectRequestOperation start];

}

- (void)openDrawer:(id)sender {
    
    // now tell the web view to change the page
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate.drawer toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
    
}

-(void)refreshOriginalPage
{
    NSLog(@"refreshOriginalPage");
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self loadLetterData];
}

-(void)webViewDidFinishLoad:(UIWebView *)a_webView {
    
    NSString *height = [a_webView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight"];
    [[RODItemStore sharedStore] updateLetterByIndex:self.letter_index letter_height:height];
    
    self.letter_index++;    
    
    if(self.letter_index == [[[RODItemStore sharedStore] allLetters] count]) {
        self.loaded = true;
        [self loadLetterData];
        return;
    }
    
    RKFullLetter *full_letter;
    full_letter = [[[RODItemStore sharedStore] allLetters] objectAtIndex:self.letter_index];
    [self.testWebView loadHTMLString:full_letter.letterMessage baseURL:nil];
        
}

- (void)nextButtonClicked:(UIButton *)button
{
    [self clearLettersAndReset];
    [[RODItemStore sharedStore] goNextPage];
}

-(void)backButtonClicked:(UIButton *)button
{
    if([[RODItemStore sharedStore] current_page] > 1) {
        [self clearLettersAndReset];
        [[RODItemStore sharedStore] goBackPage];
    }
}

-(void)clearLettersAndReset
{
    
    for (UIView *subview in self.scrollView.subviews) {        
        if([subview class] == [PagerViewController class] || [subview class] == [ScrollViewItem class]) {
            [subview performSelector:@selector(removeFromSuperview)];
        }
    }
    
    self.scrollView.contentSize = self.scrollView.frame.size;
    
    [self.scrollView setContentOffset:CGPointZero animated:YES];
    [self.indicator startAnimating];
    
    self.loaded = false;
    self.letter_index = 0;
}

- (NSDate*) getDateFromJSON:(NSString *)dateString
{
    // Expect date in this format "/Date(1268123281843)/"
    int startPos = [dateString rangeOfString:@"("].location+1;
    int endPos = [dateString rangeOfString:@")"].location;
    NSRange range = NSMakeRange(startPos,endPos-startPos);
    unsigned long long milliseconds = [[dateString substringWithRange:range] longLongValue];
//    NSLog(@"%llu",milliseconds);
    NSTimeInterval interval = milliseconds/1000;
    return [NSDate dateWithTimeIntervalSince1970:interval];
}

@end
