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
    [self setDefaultData];
    [self addNotificationToRecievePaymentCompletion];
    
    //Add Loader/Spinner to the current view
    spinner = [Spinner init];
    [spinner setText:@"Please wait.."];
    [spinner hide];
    [self.view addSubview:spinner];
    
    //Set data mutable array to choose from prod and test environment
    environment = [NSMutableDictionary alloc];
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
 }

- (void)keyboardWillShow:(NSNotification *) notification {
    keyboardHeight = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height - 100;
}

- (void)setDefaultData {
    self.nameTextField.text = @"Sukanya";
    self.emailTextField.text = @"sukanya@innoventestech.com";
    self.phoneNumberTextField.text = @"9952620490";
    self.amountTextField.text = @"10.00";
    self.descriptionTextField.text = @"Test Description";
}

- (void)addNotificationToRecievePaymentCompletion {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(paymentCompletionCallBack:) name:@"JUSPAY" object:nil];
}

- (void) paymentCompletionCallBack:(NSNotification *) notification {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSObject *userCancelled = [defaults objectForKey:@"USER-CANCELLED"];
    if (userCancelled != nil) {
        
    }
    NSObject *onRedirectURL = [defaults objectForKey:@"ON-REDIRECT-URL"];
    if (onRedirectURL != nil){
        
    }
    NSObject *cancelledOnVerify = [defaults objectForKey:@"USER-CANCELLED-ON-VERIFY"];
    if (cancelledOnVerify != nil){
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)showPaymentView:(id)sender {
    self.payButton.enabled = false;
    [textField resignFirstResponder];
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:true];
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
    Order *order = [Order init];
    order.transactionID = transactionID;
    order.authToken = accessToken;
    order.buyerName = self.nameTextField.text;
    order.buyerEmail = self.emailTextField.text;
    order.buyerPhone = self.phoneNumberTextField.text;
    order.amount = self.amountTextField.text;
    order.orderDescription = self.descriptionTextField.text;
    order.webhook = @"http://your.server.com/webhook/";
    
    NSDictionary *nameValidity = [order isValidName];
    NSDictionary *emailValidity = [order isValidEmail];
    NSDictionary *phoneValidity = [order isValidPhone];
    NSDictionary *amountValidity = [order isValidAmount];
    NSDictionary *descriptionValidity = [order isValidDescription];
    
    [self invalidName:![[nameValidity objectForKey:@"validity"] boolValue] message:[nameValidity objectForKey:@"error"]];
    [self invalidEmail:![[emailValidity objectForKey:@"validity"] boolValue] message:[emailValidity objectForKey:@"error"]];
    [self invalidName:![[phoneValidity objectForKey:@"validity"] boolValue] message:[phoneValidity objectForKey:@"error"]];
    [self invalidName:![[amountValidity objectForKey:@"validity"] boolValue] message:[amountValidity objectForKey:@"error"]];
    [self invalidName:![[descriptionValidity objectForKey:@"validity"] boolValue] message:[descriptionValidity objectForKey:@"error"]];
    
    if ([order isValid]){
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [spinner show];
        });
        Request *request = [Request init];
        request = [request initWithOrder:order orderRequestCallBack:self];
        [request execute];
    }
}

-(void)invalidName:(BOOL) show message:(NSString *)message {
    if (show) {
        [self.nameErrorLabel setHidden:false];
        self.nameErrorLabel.text = message;
        self.nameDivider.backgroundColor = [UIColor redColor];
    }else{
        [self.nameErrorLabel setHidden:true];
        self.nameDivider.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }
}

-(void)invalidEmail:(BOOL) show message:(NSString *)message {
    if (show) {
        [self.emailErrorLabel setHidden:false];
        self.emailErrorLabel.text = message;
        self.emailDivider.backgroundColor = [UIColor redColor];
    }else{
        [self.emailErrorLabel setHidden:true];
        self.emailDivider.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }
}

-(void)invalidPhoneNumber:(BOOL) show message:(NSString *)message {
    if (show) {
        [self.phoneNumberErrorLabel setHidden:false];
        self.phoneNumberErrorLabel.text = message;
        self.phoneNumberDivider.backgroundColor = [UIColor redColor];
    }else{
        [self.phoneNumberErrorLabel setHidden:true];
        self.phoneNumberDivider.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }
}

-(void)invalidAmount:(BOOL) show message:(NSString *)message {
    if (show) {
        [self.amountErrorLabel setHidden:false];
        self.amountErrorLabel.text = message;
        self.amountDivider.backgroundColor = [UIColor redColor];
    }else{
        [self.amountErrorLabel setHidden:true];
        self.amountDivider.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }
}

-(void)invalidDescription:(BOOL) show message:(NSString *)message {
    if (show) {
        [self.descriptionErrorLabel setHidden:false];
        self.descriptionErrorLabel.text = message;
        self.descriptionDivider.backgroundColor = [UIColor redColor];
    }else{
        [self.descriptionErrorLabel setHidden:true];
        self.descriptionDivider.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }
}


-(void)onFinishWithOrder:(Order *)order error:(NSString *)error{
    if (error.length != 0){
        dispatch_async(dispatch_get_main_queue(), ^(void){
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
                      
                 });
             }
         }else{
             [self showAlert:@"Failed to fetch transaction status"];
         }
     }];
}

-(void)refundPayment{
    
}

@end
