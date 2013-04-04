//
//  RdioSearchViewController.m
//  RDJukebox
//
//  Created by Kevin Nelson on 11/12/12.
//  Copyright (c) 2012 Rdio. All rights reserved.
//

#import "RdioSearchViewController.h"

#import "HelloAppDelegate.h"

@interface RdioSearchViewController()

@property (strong, nonatomic) RDAPIRequest *searchRequest;
@property (strong, nonatomic) NSDictionary *searchResults;

- (void)initiateSearch:(NSString *)query;

@end

@implementation RdioSearchViewController

@synthesize searchView;
@synthesize trackSearchBar;
@synthesize trackSearchDisplayController;
@synthesize resultsTable;

@synthesize searchRequest;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.trackSearchDisplayController = [[UISearchDisplayController alloc]
                                         initWithSearchBar:trackSearchBar
                                         contentsController:self];
    self.trackSearchDisplayController.delegate = self;
    self.trackSearchDisplayController.searchResultsDataSource = self;
    self.trackSearchDisplayController.searchResultsDelegate = self;
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initiateSearch:(NSString *)query
{
    NSLog(@"Search for %@", query);
    if (self.searchRequest) {
        //search request already exists!
        [self.searchRequest cancel];
        self.searchRequest = nil;
    }
    
    self.searchRequest = [[HelloAppDelegate rdioInstance] callAPIMethod:@"search"
                                                         withParameters:@{
                                                            @"query": query,
                                                            @"types": @"Album"
                                                          }
                                                          delegate:self];
  

}

#pragma mark
#pragma RDAPIRequestDelegate methods

- (void)rdioRequest:(RDAPIRequest *)request didLoadData:(id)data
{
    NSLog(@"request succeeded and got %@", data);
    self.searchResults = (NSDictionary *)data;
    self.searchRequest = nil;
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (void)rdioRequest:(RDAPIRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Request failed! With error %@", error);
}

#pragma mark
#pragma UISearchBarDelegate methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSLog(@"Search text changed to %@", searchText);
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self initiateSearch:searchString];
    return NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    return NO;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1; // tracks, maybe artists later.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.searchResults) {
        NSInteger resultCount = [[self.searchResults objectForKey:@"number_results"] integerValue];
        return resultCount;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"searchResultCell";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    NSDictionary *metadata = [[self.searchResults objectForKey:@"results"] objectAtIndex:indexPath.row];
    
    NSString *resultText = [NSString stringWithFormat:@"\"%@\" - %@ (%@)", [metadata objectForKey:@"name"],
                                                                           [metadata objectForKey:@"artist"],
                                                                           [metadata objectForKey:@"album"]];
    
    [cell.textLabel setText:resultText];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *album = [[self.searchResults objectForKey:@"results"] objectAtIndex:indexPath.row];
    NSLog(@"Selected Album! %@", album);
  
    // this is deliberately inefficent, to make sure using queueSource a lot doesn't cause problems.
    NSMutableArray *tracks = [NSMutableArray arrayWithArray:[album objectForKey:@"trackKeys"]];
    RDPlayer *player = [[HelloAppDelegate rdioInstance] player];
    [player playSource:[tracks objectAtIndex:0]];
    [tracks removeObjectAtIndex:0];
    for (NSString *trackKey in tracks) {
        [player queueSource:trackKey];
    }
  
    [self dismissViewControllerAnimated:YES completion:nil];
}




@end
