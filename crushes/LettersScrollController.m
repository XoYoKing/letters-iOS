//
//  LettersScrollController.m
//  crushes
//
//  Created by Seth Hayward on 7/24/13.
//  Copyright (c) 2013 Seth Hayward. All rights reserved.
//

#import "LettersScrollController.h"
#import "MMDrawerBarButtonItem.h"
#import "RODItemStore.h"
#import "RKFullLetter.h"
#import "ScrollViewItem.h"
#import "AppDelegate.h"

@implementation LettersScrollController
@synthesize current_receive, loaded;

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

        [self.view setHidden:true];
 
        [self.indicator startAnimating];
        
        [self.scrollView setDelegate:self];
        current_receive = 0;
        loaded = false;
        
    }
    return self;
}

-(void)loadLetterData
{
    
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
                
        scv.view.frame = CGRectMake(0, yOffset, self.view.bounds.size.width, letter_height + 80);
        
        [scv.webView setDelegate:self];
        
        [scv.webView loadHTMLString:full_letter.letterMessage baseURL:nil];
        [scv.buttonHearts setTitle:[full_letter.letterUp stringValue] forState:UIScrollViewDecelerationRateNormal];
        [scv.buttonHearts addTarget:self action:@selector(clickedHeart:) forControlEvents:UIControlEventTouchUpInside];
        [scv.buttonHearts setTag:[full_letter.Id integerValue]];
        
        [scv.labelHearts setText:[full_letter.letterUp stringValue]];
        
        if([full_letter.letterComments isEqualToNumber:[NSNumber numberWithInt:0]]) {
            [scv.labelComments  setHidden:true];
        } else {
            
            if([full_letter.letterComments integerValue] < 2) {
                [scv.labelComments setText:@"1 comment"];
            } else {
                [scv.labelComments setText:[NSString stringWithFormat:@"%@ comments", full_letter.letterComments]];
            }
                 
      }
        
        [scv setCurrent_letter:full_letter];
        
        yOffset = yOffset + (letter_height + 80);
                
        [self.scrollView addSubview:scv.view];
        
    }
    
    [self.scrollView setContentSize:CGSizeMake(self.view.bounds.size.width, yOffset)];
    
    
    // now try looping through and resetting everything?
    
}

-(void)clickedHeart:(UIButton *)button
{
    
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
    
    NSString *real_url = [NSString stringWithFormat:@"http://www.letterstocrushes.com/home/vote/%d", button.tag];
    
    [objectManager addResponseDescriptor:responseDescriptor];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:real_url]];
    
    RKObjectRequestOperation *objectRequestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor] ];
    
    [objectRequestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        RKFullLetter *letter = mappingResult.array[0];
        NSLog(@"Voted on letter %@", letter.Id);
        
        [button setTitle:[NSString stringWithFormat:@"%@", letter.letterUp] forState:UIControlStateNormal];
        
    } failure: ^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Error voting: %@", error);
    }];
    
    [objectRequestOperation start];

}

-(void)redrawScroll
{
    [[RODItemStore sharedStore] removeReferences];
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    // get new height of scrollview from all subviews
    // thanks to William Jockusch on stackoverflow.com/questions/4018729
    
    CGRect contentRect = CGRectZero;
    for (UIView *view in self.scrollView.subviews) {
        contentRect = CGRectUnion(contentRect, view.frame);
    }
    
    self.scrollView.contentSize = contentRect.size;
    
    [self loadLetterData];
}


- (void)openDrawer:(id)sender {
    
    // now tell the web view to change the page
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate.drawer toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
    
}

-(void)refreshOriginalPage
{
    [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self loadLetterData];
}


-(void)webViewDidStartLoad:(UIWebView *)a_webView
{
}

-(void)webViewDidFinishLoad:(UIWebView *)a_webView {
    
    if(loaded == true) {        
        return;
    }
    
    NSString *height = [a_webView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight"];
    NSString *hidden_id = [a_webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('letter_id').innerHTML"];
        
    // now loop through the data store
    // assign the value
    // then check to see if th eothers have finished loading
    // if so, then ask the panel to redraw itself

    Boolean found_default = false;
    
    for(int i = 0; i < [[[RODItemStore sharedStore] allLetters] count]; i++)
    {
        
        RKFullLetter *letter = [[[RODItemStore sharedStore] allLetters] objectAtIndex:i];
        if([[letter.Id stringValue] isEqualToString:hidden_id]) {
            [[RODItemStore sharedStore] updateLetter:letter.Id letter_height:height];
        }
        
        if([letter.letterTags isEqualToString:@"0"]) {
            found_default = true;
        }
        
    }
    
    if(found_default == false) {
        loaded = true;
        [self.indicator stopAnimating];
        [self.view setHidden:false];
        [self loadLetterData];
    }
    // now, see if the rest of the letters have received
    // their height settings, which will allow us to reload
    
    
}



@end
