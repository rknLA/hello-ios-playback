//
//  RdioSearchViewController.h
//  RDJukebox
//
//  Created by Kevin Nelson on 11/12/12.
//  Copyright (c) 2012 Rdio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Rdio/RDAPIRequest.h>

@interface RdioSearchViewController : UIViewController <UISearchDisplayDelegate,
                                                        RDAPIRequestDelegate,
                                                        UITableViewDelegate,
                                                        UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UIView *searchView;
@property (strong, nonatomic) IBOutlet UISearchDisplayController* trackSearchDisplayController;
@property (strong, nonatomic) IBOutlet UISearchBar *trackSearchBar;
@property (strong, nonatomic) IBOutlet UITableView *resultsTable;

@end
