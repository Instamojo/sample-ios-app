//
//  ViewController.h
//  Sample
//
//  Created by Sukanya Raj on 21/03/17.
//  Copyright © 2017 Sukanya Raj. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Instamojo;

@interface ViewController : UIViewController <UITextFieldDelegate,OrderRequestCallBack>

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) IBOutlet UILabel *selectedEnv;

@property (strong, nonatomic) IBOutlet UISwitch *environmentSwitch;
- (IBAction)environmentSelection:(UISwitch *)sender;

@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (strong, nonatomic) IBOutlet UITextField *phoneNumberTextField;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet UITextField *amountTextField;
@property (strong, nonatomic) IBOutlet UITextField *descriptionTextField;

@property (strong, nonatomic) IBOutlet UIButton *payButton;
- (IBAction)showPaymentView:(id)sender;

@property (strong, nonatomic) IBOutlet UIView *nameDivider;
@property (strong, nonatomic) IBOutlet UIView *emailDivider;
@property (strong, nonatomic) IBOutlet UIView *phoneNumberDivider;
@property (strong, nonatomic) IBOutlet UIView *descriptionDivider;

@property (strong, nonatomic) IBOutlet UILabel *nameErrorLabel;
@property (strong, nonatomic) IBOutlet UILabel *emailErrorLabel;
@property (strong, nonatomic) IBOutlet UILabel *phoneNumberErrorLabel;
@property (strong, nonatomic) IBOutlet UILabel *amountErrorLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionErrorLabel;
@property (strong, nonatomic) IBOutlet UIView *amountTextfieldDivider;


@end

