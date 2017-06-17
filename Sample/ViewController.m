//
//  ViewController.m
//  Sample
//
//  Created by Sukanya Raj on 21/03/17.
//  Copyright © 2017 Sukanya Raj. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

NSString *transactionID;
NSString *accessToken;
Spinner *spinner;
NSMutableDictionary *environment;
UITextField *textField;
float keyboardHeight;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addNotificationToRecievePaymentCompletion];
    
    //Add Loader/Spinner to the current view
    spinner = [[Spinner alloc]initWithText:@"Please wait.."];
    [spinner hide];
    [self.view addSubview:spinner];
    
    //Set data mutable array to choose from prod and test environment
    environment = [[NSMutableDictionary alloc]init];
    [environment setObject:@"production" forKey:@"Production Environment"];
    [environment setObject:@"test" forKey:@"Test Environment"];
    
    //Delegate texfield to handle next button click on keyboard
    self.amountTextField.delegate = self;
    self.emailTextField.delegate = self;
    self.nameTextField.delegate = self;
    self.descriptionTextField.delegate = self;
    self.phoneNumberTextField.delegate = self;
    
    //set nameTextField as inital Textfield to handle resigning the responder
    textField = self.nameTextField;
   
    //Set observer to handle keybaord navigations
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    self.nameTextField.delegate = self;
    self.amountTextField.delegate = self;
    self.emailTextField.delegate = self;
    self.descriptionTextField.delegate = self;
    self.phoneNumberTextField.delegate = self;
    self.scrollView.scrollEnabled = YES;
    
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
    NSInteger nextTag = textField.tag + 1;
    // Try to find next responder
    UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        // Found next responder, so set it.
        [nextResponder becomeFirstResponder];
        if (textField != self.nameTextField){
            [self.scrollView setContentOffset:CGPointMake(0, keyboardHeight) animated:true];
        }
    } else {
        // Not found, so remove keyboard.
        [self.scrollView setContentOffset:CGPointMake(0, 0) animated:true];
        [textField resignFirstResponder];
    }
    return NO; // We do not want UITextField to insert line-breaks.
}

- (void)keyboardWillShow:(NSNotification *) notification {
    keyboardHeight = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height - 100;
}

- (void)addNotificationToRecievePaymentCompletion {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(paymentCompletionCallBack:) name:@"INSTAMOJO" object:nil];
}

- (void) paymentCompletionCallBack:(NSNotification *) notification {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSObject *userCancelled = [defaults objectForKey:@"USER-CANCELLED"];
    if (userCancelled != nil) {
        [self showAlert:@"Transaction cancelled by user, back button was pressed."];
    }
    
    NSObject *onRedirectURL = [defaults objectForKey:@"ON-REDIRECT-URL"];
    if (onRedirectURL != nil){
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self checkPaymentStatus];
        });
    }
    
    NSObject *cancelledOnVerify = [defaults objectForKey:@"USER-CANCELLED-ON-VERIFY"];
    if (cancelledOnVerify != nil){
        [self showAlert:@"Transaction cancelled by user when trying to verify payment."];
          dispatch_async(dispatch_get_main_queue(), ^(void){
        [self checkPaymentStatus];
          });
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
     self.payButton.enabled = true;
}


- (IBAction)showPaymentView:(id)sender {
    self.payButton.enabled = false;
    [textField resignFirstResponder];
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:true];
    [self fetchOrder];
}

- (IBAction)environmentSelection:(UISwitch *)sender {
    if ([sender isOn]){
        self.selectedEnv.text = @"Production Environment";
        [Instamojo setBaseUrlWithUrl:@"https://api.instamojo.com/"];
    }else{
        self.selectedEnv.text = @"Test Environment";
        [Instamojo setBaseUrlWithUrl:@"https://test.instamojo.com/"];
    }
}

-(void)showAlert:(NSString *) message {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:@"Alert"
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"Ok"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action) {
                             //Handle your yes please button action here
                         }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}


-(void)fetchOrder {
    [spinner show];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://sample-sdk-server.instamojo.com/create"]];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    NSString *params = [NSString stringWithFormat:@"env=%@",[environment objectForKey:self.selectedEnv.text]];
    [request setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [spinner hide];
        });
        if (data.length > 0 && connectionError == nil){
             NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            if ([response objectForKey:@"error"] != nil){
                NSString *errorMessage = [response objectForKey:@"error"];
                [self showAlert: errorMessage];
            }else{
                transactionID = [response objectForKey:@"transaction_id"];
                accessToken = [response objectForKey:@"access_token"];
                [self createOrder];
            }
        }else{
            [self showAlert:@"Failed to fetch order tokens"];
        }
     }];
}

-(void)createOrder {
    NSString *name = self.nameTextField.text;
    NSString *email = self.emailTextField.text;
    NSString *buyerPhone = self.phoneNumberTextField.text;
    NSString *amount = self.amountTextField.text;
    NSString *orderDescription = self.descriptionTextField.text;
    NSString *webhook = @"http://your.server.com/webhook/";
    
    Order *order = [[Order alloc]initWithAuthToken:accessToken transactionID:transactionID buyerName:name buyerEmail:email buyerPhone:buyerPhone amount:amount description:orderDescription webhook:webhook];
        NSDictionary *nameValidity = [order isValidName];
        NSDictionary *emailValidity = [order isValidEmail];
        NSDictionary *phoneValidity = [order isValidPhone];
        NSDictionary *amountValidity = [order isValidAmount];
        NSDictionary *descriptionValidity = [order isValidDescription];
    
        [self invalidName:[[nameValidity objectForKey:@"validity"] boolValue] message:[nameValidity objectForKey:@"error"]];
    
        [self invalidEmail:[[emailValidity objectForKey:@"validity"] boolValue] message:[emailValidity objectForKey:@"error"]];
    
        [self invalidPhoneNumber:[[phoneValidity objectForKey:@"validity"] boolValue] message:[phoneValidity objectForKey:@"error"]];
    
        [self invalidAmount:[[amountValidity objectForKey:@"validity"] boolValue] message:[amountValidity objectForKey:@"error"]];
    
        [self invalidDescription:[[descriptionValidity objectForKey:@"validity"] boolValue] message:[descriptionValidity objectForKey:@"error"]];
    
    if ([order isValid]){
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [spinner show];
        });
        Request *request = [[Request alloc]initWithOrder:order orderRequestCallBack:self];
        [request execute];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^(void){
            self.payButton.enabled = true;
        });
    }
}

-(void)invalidName:(BOOL) validity message:(NSString *)message {
    if (validity) {
        self.nameErrorLabel.hidden = true;
        self.nameDivider.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }else{
        self.nameErrorLabel.hidden = false;
        self.nameErrorLabel.text = message;
        self.nameDivider.backgroundColor = [UIColor redColor];
    }
}

-(void)invalidEmail:(BOOL) validity message:(NSString *)message {
    if (validity) {
        self.emailErrorLabel.hidden = true;
        self.emailDivider.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }else{
        self.emailErrorLabel.hidden = false;
        self.emailErrorLabel.text = message;
        self.emailDivider.backgroundColor = [UIColor redColor];
    }
}

-(void)invalidPhoneNumber:(BOOL) validity message:(NSString *)message {
    if (validity) {
        self.phoneNumberErrorLabel.hidden = true;
        self.phoneNumberDivider.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }else{
        self.phoneNumberErrorLabel.hidden = false;
        self.phoneNumberErrorLabel.text = message;
        self.phoneNumberDivider.backgroundColor = [UIColor redColor];
    }
}

-(void)invalidAmount:(BOOL) validity message:(NSString *)message {
    if (validity) {
        self.amountErrorLabel.hidden = true;
        self.amountTextfieldDivider.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }else{
        self.amountErrorLabel.hidden = false;
        self.amountErrorLabel.text = message;
        self.amountTextfieldDivider.backgroundColor = [UIColor redColor];
    }
}

-(void)invalidDescription:(BOOL) validity message:(NSString *)message {
    if (validity) {
        self.descriptionErrorLabel.hidden = true;
        self.descriptionDivider.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }else{
        self.descriptionErrorLabel.hidden = false;
        self.descriptionErrorLabel.text = message;
        self.descriptionDivider.backgroundColor = [UIColor redColor];
    }
}


-(void)onFinishWithOrder:(Order *)order error:(NSString *)error{
    if (error.length != 0){
        dispatch_async(dispatch_get_main_queue(), ^(void){
            self.payButton.enabled = true;
            [spinner hide];
            [self showAlert:error];
        });
    }else{
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [spinner hide];
            [Instamojo invokePaymentOptionsViewWithOrder:order];
        });
    }
}

-(void)checkPaymentStatus{
    [spinner show];

    
    if (accessToken == nil){
        return;
    }
     NSString *params = [NSString stringWithFormat:@"env=%@&transaction_id=%@",[environment objectForKey:self.selectedEnv.text],transactionID];
    NSString *url = [NSString stringWithFormat:@"https://sample-sdk-server.instamojo.com/status?%@", params];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"GET";
    [request addValue:[NSString stringWithFormat:@"Bearer %@",accessToken] forHTTPHeaderField:@"Authorization"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         dispatch_async(dispatch_get_main_queue(), ^(void){
             [spinner hide];
         });
         if (data.length > 0 && connectionError == nil){
             NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
             NSString *amount = [response objectForKey:@"amount"];
             NSString *status = [response objectForKey:@"status"];
             if ([status isEqualToString:@"completed"]){
                 NSMutableArray *payments = [response objectForKey:@"payments"];
                 NSString *paymentID = [[payments objectAtIndex:0]objectForKey:@"id"];
                 NSString *status = [NSString stringWithFormat:@"Transaction Successful for id - %@. Refund will be initated.", paymentID];
                 [self showAlert:status];
                 dispatch_async(dispatch_get_main_queue(), ^(void){
                     [self refundPayment:amount];
                 });
             }else{
                 [self showAlert:@"Transaction Pending"];
             }
         }else{
             [self showAlert:@"Failed to fetch transaction status"];
         }
     }];
}

-(void)refundPayment:(NSString *) amount{
    [spinner show];
    NSString *params = [NSString stringWithFormat:@"env=%@&transaction_id=%@&amount=%@&type=PTH&body=Refund the Amount",[environment objectForKey:self.selectedEnv.text],transactionID,amount];
 
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://sample-sdk-server.instamojo.com/refund/"]];
    request.HTTPMethod = @"POST";
    [request setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    [request addValue:[NSString stringWithFormat:@"Bearer %@",accessToken] forHTTPHeaderField:@"Authorization"];
    [request addValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded"] forHTTPHeaderField:@"Content-Type"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         dispatch_async(dispatch_get_main_queue(), ^(void){
             [spinner hide];
         });
         if (data.length > 0 && connectionError == nil){
             [self showAlert:@"Refund intiated successfully"];
         }else{
             [self showAlert:@"Failed to intiate refund"];
         }
     }];
}

-(void)fetchOrderFromInstamojo:(NSString *) orderID accessToken:(NSString *)accessToken{
    [spinner show];
    Request *request = [[Request alloc] initWithOrderID:orderID accessToken:accessToken orderRequestCallBack:self];
    [request execute];
}

@end
