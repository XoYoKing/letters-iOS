//
//  WebViewController.m
//  crushes
//
//  Created by Seth Hayward on 12/6/12.
//  Copyright (c) 2012 Seth Hayward. All rights reserved.
//

#import "WebViewController.h"
#import "AppDelegate.h"
#import "RKFullLetter.h"

@implementation WebViewController
@synthesize viewType, currentWebView, _sessionChecked, loadingIndicator;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil viewType:(WebViewType)type
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
        [self setViewType:type];
        
        if ([self viewType] == WebViewTypeHome) {
            UITabBarItem *tbi_home = [self tabBarItem];
            [tbi_home setTitle:@"Home"];
            [tbi_home setImage:[UIImage imageNamed:@"home.png"]];
        } else if ([self viewType] == WebViewTypeMore) {
            UITabBarItem *tbi_more = [self tabBarItem];
            [tbi_more setTitle:@"More"];
            [tbi_more setImage:[UIImage imageNamed:@"medical.png"]];
        } else if ([self viewType] == WebViewTypeBookmarks) {
            UITabBarItem *tbi_bookmarks = [self tabBarItem];
            [tbi_bookmarks setTitle:@"Bookmarks"];
            [tbi_bookmarks setImage:[UIImage imageNamed:@"bookmark.png"]];
        } else if ([self viewType] == WebViewTypeSearch) {
            UITabBarItem *tbi_search = [self tabBarItem];
            [tbi_search setTitle:@"Search"];
            [tbi_search setImage:[UIImage imageNamed:@"search.png"]];
        }
                
    }
    
    return self;
}

- (void)refreshWebView
{
    NSLog(@"Forcing refresh.");
    
    NSString *current_url = _webView.request.URL.absoluteString;
    
    if([current_url isEqualToString:@"about:blank"]) {
        [self refreshOriginalPage];
        return;
    }
    
    [_webView stopLoading];
    
    NSURL *url = [NSURL URLWithString: current_url];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageAllowed timeoutInterval:20];
    [NSURLConnection connectionWithRequest:request delegate:self];
    [loadingIndicator startAnimating];
    
}

- (void)refreshOriginalPage
{

    [_webView setDelegate:self];

    
    NSString *url = @"http://www.letterstocrushes.com/mobile";

    switch(viewType) {
        case WebViewTypeHome:
            url = [url stringByAppendingString:@"/"];
            break;
        case WebViewTypeMore:
            url = [url stringByAppendingString:@"/more"];
            break;
        case WebViewTypeBookmarks:
            url = [url stringByAppendingString:@"/bookmarks"];
            break;
        case WebViewTypeSearch:
            url = [url stringByAppendingString:@"/search"];
            break;
    }

    if([_webView isLoading]) {
        [_webView stopLoading];
    }
    
    currentWebView = _webView;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLCacheStorageAllowed timeoutInterval:20];
    [_webView loadRequest:request];
    
}

- (void)viewDidUnload {
    _webView = nil;
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    if(currentWebView.request.URL.absoluteString.length == 0) {
        [self refreshOriginalPage];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    
    [_webView stopLoading];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"%s error=%@", __FUNCTION__, error);
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    [loadingIndicator stopAnimating];
}

-(void)webViewDidStartLoad:(UIWebView *)webView
{
    [loadingIndicator startAnimating];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    NSString *new_url = [[request URL] path];
    NSLog(@"About to load %@", new_url);
    
    if([new_url rangeOfString:@"/edit/"].location == NSNotFound) {
        // not an edit page, so lets load it
        return YES;
    } else {
        
        NSString *letter_id = [new_url substringFromIndex:6];
        NSLog(@"letter_id: %@", letter_id);

        // get a reference to the send tab,
        // we will need to populate this screen
        // with data from the letter.
        
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        [appDelegate.tabBar setSelectedIndex:4];
        
        appDelegate.sendViewController.labelCallToAction.text = @"Edit your letter.";
        [appDelegate.sendViewController.sendButton setTitle:@"Edit" forState:UIControlStateNormal];
        
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
                
        NSString *real_url = [NSString stringWithFormat:@"http://www.letterstocrushes.com/home/getletter/%@", letter_id];
        
        [objectManager addResponseDescriptor:responseDescriptor];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:real_url]];
        
        RKObjectRequestOperation *objectRequestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor] ];
        
        [objectRequestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
            
            RKFullLetter *letter = mappingResult.array[0];
            NSLog(@"Loaded letter: %@", letter.letterMessage);
            appDelegate.sendViewController.messageText.text = letter.letterMessage;
            
            appDelegate.sendViewController.isEditing = YES;
            appDelegate.sendViewController.editingId = [NSString stringWithFormat:@"%@", letter.Id];

            appDelegate.sendViewController.tabBarItem.title = @"Edit";            
            
        } failure: ^(RKObjectRequestOperation *operation, NSError *error) {
            NSLog(@"Error loading: %@", error);
        }];
        
        [objectRequestOperation start];
         
        return NO;        
    }

}

-(void)cancelWeb
{
    NSLog(@"Timed out after 20 seconds. Forcing refresh.");
    [_webView stopLoading];
    [self refreshWebView];    
}


@end
