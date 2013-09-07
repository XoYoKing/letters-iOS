//
//  ChatViewController.m
//  crushes
//
//  Created by Seth Hayward on 9/6/13.
//  Copyright (c) 2013 Seth Hayward. All rights reserved.
//

#import "ChatViewController.h"
#import "RODItemStore.h"
#import "SignalR.h"
#import "AppDelegate.h"
#import "MMDrawerBarButtonItem.h"
#import "RKChat.h"

@implementation ChatViewController
@synthesize chatHub;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        MMDrawerBarButtonItem * leftDrawerButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(openDrawer:)];
        [self.navigationItem setLeftBarButtonItem:leftDrawerButton animated:YES];
        
        [[self navigationItem] setTitle:@"CHAT"];

        self.tableChats.rowHeight = 30;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    SRHubConnection *hubConnection = [SRHubConnection connectionWithURL:@"http://letterstocrushes.com"];
    
    chatHub = [hubConnection createHubProxy:@"VisitorUpdate"];
    
    hubConnection.started = ^{
        [chatHub invoke:@"join" withArgs:[NSArray arrayWithObject:[RODItemStore sharedStore].settings.chatName]];
        
        [chatHub on:@"addSimpleMessage" perform:self selector:@selector(addSimpleMessage:)];
        
        [RODItemStore sharedStore].connected_to_chat = true;

    };
    
    [hubConnection start];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.view endEditing:YES];
    [self sendChat];
    return YES;
}

- (void)sendChat {
    NSString *txt = self.textMessage.text;
    [chatHub invoke:@"sendChat" withArgs:[NSArray arrayWithObject:txt]];
    [self.textMessage setText:@""];
}

- (IBAction)btnSend:(id)sender {
    [self sendChat];
}

- (void)addSimpleMessage:(NSString *)chat
{
    NSLog(@"addMessage fired: %@", chat);
    [[RODItemStore sharedStore] addChat:chat];
    [self.tableChats reloadData];
}

- (void)openDrawer:(id)sender {
    // now tell the web view to change the page
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    [appDelegate.drawer toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[RODItemStore sharedStore] allChats].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
    }
    
    NSString *c = [[[RODItemStore sharedStore] allChats] objectAtIndex:[indexPath row]];

    cell.textLabel.font = [UIFont systemFontOfSize:10];
    [[cell textLabel] setText:c];
    
    return cell;
}

@end
