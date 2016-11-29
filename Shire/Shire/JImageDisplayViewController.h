//
//  JImageDisplayViewController.h
//  Shire
//
//  Created by jie on 2016/11/23.
//  Copyright © 2016年 huatengIOT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JImageDisplayViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;


@end
