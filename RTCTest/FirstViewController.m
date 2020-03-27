//
//  FirstViewController.m
//  WebRTCLearning
//
//  Created by WuChuMing on 2020/3/25.
//  Copyright © 2020 Shawn. All rights reserved.
//

#import "FirstViewController.h"
#import "SecondViewController.h"


@interface FirstViewController ()

@property (weak, nonatomic) IBOutlet UITextField *addressTF;

@property (weak, nonatomic) IBOutlet UITextField *roomTF;


@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}
- (IBAction)loginButtonClick:(id)sender {
    SecondViewController *sec = [[SecondViewController alloc] init];
    sec.roomNo = self.roomTF.text;
    sec.serverAddress = self.addressTF.text;
    sec.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:sec animated:YES completion:nil];
    
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
