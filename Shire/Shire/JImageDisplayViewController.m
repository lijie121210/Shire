//
//  JImageDisplayViewController.m
//  Shire
//
//  Created by jie on 2016/11/23.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import "JImageDisplayViewController.h"
#import "UIImageView+DownloadImage.h"

@interface JImageDisplayViewController ()

@end

@implementation JImageDisplayViewController
{
    NSMutableArray *_imageSources;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *path1 = [NSString stringWithFormat:@"https://3hsyn13u3q9dhgyrg2qh3tin-wpengine.netdna-ssl.com/wp-content/uploads/2016/11/SplitShire-3841.jpg"];
    _imageSources = [NSMutableArray arrayWithObjects:path1, path1, path1, path1, path1, path1, path1, path1, path1, path1, nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



/*
 *
 * UITableViewDataSource
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _imageSources.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSString *path = (NSString *)[_imageSources objectAtIndex:[indexPath row]];
    [[cell textLabel] setText:path];
    [[cell imageView] setImageWithURL:path placeholdImage:nil];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return false;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return false;
}

/*
 * UITableViewDelegate
 */

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 200;
}

@end
