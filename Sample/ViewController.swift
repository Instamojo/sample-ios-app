//
//  ViewController.swift
//  Sample
//
//  Created by Sukanya Raj on 06/02/17.
//  Copyright © 2017 Sukanya Raj. All rights reserved.
//

import UIKit
import Instamojo

class ViewController: UIViewController, OrderRequestCallBack, UITextFieldDelegate {

    @IBOutlet var payButton: UIButton!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet weak var selectedEnv: UILabel!
    @IBOutlet weak var environmentSwitch: UISwitch!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneNumberTextfield: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    var transactionID: String!
    var accessToken: String!
    var spinner: Spinner!
    var environment: [String : String]!
    var keyboardHeight: Int!
    var textField : UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        defaultData()
        let notificationName = Notification.Name("JUSPAY")
        spinner = Spinner(text : "Please Wait..")
        spinner.hide()
        self.view.addSubview(spinner)
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(self.juspayCallBack), name: notificationName, object: nil)
        environment = ["Production Environment": "production", "Test Environment": "test"]

        //Delegate texfield to handle next button click on keyboard
        self.amountTextField.delegate = self
        self.emailTextField.delegate = self
        self.nameTextField.delegate = self
        self.descriptionTextField.delegate = self
        self.phoneNumberTextfield.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        self.textField = self.nameTextField
    }

    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = Int(keyboardSize.height) - 100
        }
    }

    func juspayCallBack() {
        if UserDefaults.standard.value(forKey: "USER-CANCELLED") != nil {
            self.showAlert(errorMessage: "Transaction cancelled by user, back button was pressed.")
        }

        if UserDefaults.standard.value(forKey: "ON-REDIRECT-URL") != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.checkPaymentStatus()
            }
        }

        if UserDefaults.standard.value(forKey: "USER-CANCELLED-ON-VERIFY") != nil {
            self.showAlert(errorMessage: "Transaction cancelled by user when trying to verify payment")
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.checkPaymentStatus()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func environmentSelection(_ sender: UISwitch) {
        if sender.isOn {
            selectedEnv.text = "Production Environment"
            Instamojo.setBaseUrl(url: "https://api.instamojo.com/")
            Logger.logDebug(tag: "Environment", message: environment[selectedEnv.text!]!)
        } else {
            selectedEnv.text = "Test Environment"
            Instamojo.setBaseUrl(url: "https://test.instamojo.com/")
            Logger.logDebug(tag: "Environment", message: environment[selectedEnv.text!]!)
        }
    }

    func defaultData() {
        nameTextField.text = "Sukanya"
        emailTextField.text = "sukanya@innoventestech.com"
        phoneNumberTextfield.text = "9952620490"
        amountTextField.text = "10.00"
        descriptionTextField.text = "Test Description"
    }

    @IBAction func showPaymentView(_ sender: Any) {
        payButton.isEnabled = false
        self.textField.resignFirstResponder()
        scrollView.setContentOffset(CGPoint.init(x: 0, y: 0), animated: true)
        spinner.show()
        fetchOrder()
    }

    func fetchOrder() {
        let url: String = "https://sample-sdk-server.instamojo.com/create"
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        request.httpMethod = "POST"
        let session = URLSession.shared
        let params = ["env": environment[selectedEnv.text!]]
        request.setBodyContent(parameters: params)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, _, error -> Void in
            self.spinner.hide()
            self.payButton.isEnabled = true
            if error == nil {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as?  [String:Any] {
                        Logger.logDebug(tag: "Dictonary", message: String(describing: jsonResponse))
                        if jsonResponse["error"] != nil {
                            if let errorMessage = jsonResponse["error"] as? String {
                             Logger.logError(tag: " Sample - Fetch Token", message: errorMessage)
                                // Show an alert with the error message recieved from the server
                                self.showAlert(errorMessage: errorMessage)
                            }
                        } else {

                            Logger.logDebug(tag: " Sample - Fetch Token", message: "Response: \(jsonResponse)")

                            let transactionID = jsonResponse["transaction_id"] as? String
                            let accessToken = jsonResponse["access_token"] as? String

                            //Create an order using the transaction_id and access_token recieved
                            self.createOrder(transactionID: transactionID!, accessToken: accessToken!)
                        }
                    }
                } catch {
                    Logger.logError(tag: " Sample - Fetch Token", message: String(describing: error))
                    self.showAlert(errorMessage: "Failed to fetch order tokens")
                }
            } else {
                print(error!.localizedDescription)
                self.showAlert(errorMessage: "Failed to fetch order tokens")
            }
        })
        task.resume()
    }

    func createOrder(transactionID: String, accessToken: String) {
        self.transactionID = transactionID
        self.accessToken = accessToken

        let order = self.formAnOrder(transactionID: transactionID, accessToken: accessToken)

        if order.isValidToCreateOrder().validity {
            self.spinner.show()
            let request = Request.init(order: order, orderRequestCallBack: self)
            request.execute()
        } else {
            DispatchQueue.main.async {
                self.spinner.hide()
                self.showAlert(errorMessage: order.isValid().error)
            }
        }
    }

    func formAnOrder(transactionID: String, accessToken: String) -> Order {
        let buyerName = self.nameTextField.text!
        let buyerEmail = self.emailTextField.text
        let buyerPhone = self.phoneNumberTextfield.text
        let amount = self.amountTextField.text
        let description = self.descriptionTextField.text
        let webHook = "http://your.server.com/webhook/"

        let order: Order =  Order.init(authToken : accessToken, transactionID : transactionID, buyerName : buyerName, buyerEmail : buyerEmail!, buyerPhone : buyerPhone!, amount : amount!, description : description!, webhook : webHook)

        return order
    }

    func showAlert(errorMessage: String) {
        let alert = UIAlertController(title: "", message: errorMessage, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    //To asssing next responder
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == self.nameTextField) {
            self.textField = self.emailTextField
            self.emailTextField.becomeFirstResponder()
        } else if (textField == self.emailTextField) {
            self.textField = self.phoneNumberTextfield
            self.phoneNumberTextfield.becomeFirstResponder()
        } else if(textField == self.phoneNumberTextfield) {
            self.textField = self.amountTextField
            self.amountTextField.becomeFirstResponder()
            scrollView.setContentOffset(CGPoint.init(x: 0, y: keyboardHeight), animated: true)
        } else if (textField == self.amountTextField) {
            self.textField = self.descriptionTextField
            self.descriptionTextField.becomeFirstResponder()
            scrollView.setContentOffset(CGPoint.init(x: 0, y: keyboardHeight), animated: true)
        } else {
            textField.resignFirstResponder()
            scrollView.setContentOffset(CGPoint.init(x: 0, y: 0), animated: true)
        }
        return false
    }

    func onFinish(order: Order, error: String) {
        if !error.isEmpty {
            DispatchQueue.main.async {
                self.spinner.hide()
                self.showAlert(errorMessage: error)
            }
        } else {
            DispatchQueue.main.async {
                self.spinner.hide()
                Instamojo.invokePaymentOptionsView(order : order)
            }
        }
    }

    func checkPaymentStatus() {
        self.spinner.show()
        if accessToken == nil {
            return
        }
        let env = self.environment[selectedEnv.text!]
        let params = ["env": env, "transaction_id": self.transactionID]
        let parameterArray = params.map { (key, value) -> String in
            return "\(key)=\((value as AnyObject))"
        }
        let values = parameterArray.joined(separator: "&")
        Logger.logDebug(tag: "Params", message: values)
        let url: String = "https://sample-sdk-server.instamojo.com/status?" + values
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        request.httpMethod = "GET"
        let session = URLSession.shared
        request.addValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")

        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            Logger.logDebug(tag: "Payment Status", message: String(describing: response))
            DispatchQueue.main.async {
                self.spinner.hide()
            }
            if error == nil {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as?  [String:Any] {
                        Logger.logDebug(tag: "Response JSON", message: String(describing: jsonResponse))
                        let amount = jsonResponse["amount"] as? String
                        let payments = jsonResponse["payments"] as? [[String :Any]]
                        let status = jsonResponse["status"] as? String
                        if status == "completed"{
                            let id = payments?[0]["id"] as? String
                            self.showAlert(errorMessage: "Transaction Successful for id - " + id!)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.refundTheAmount(amount: amount!, transctionID: self.transactionID)
                            }
                        } else {
                            self.showAlert(errorMessage: "Transaction still pending")
                        }
                    }
                } catch {
                    Logger.logError(tag: "Caught Exception", message: String(describing: error))
                }
            } else {
                print(error!.localizedDescription)
            }
        })
        task.resume()
    }

    func refundTheAmount(amount: String, transctionID: String) {
        self.spinner.show()
        let url: String = "https://sample-sdk-server.instamojo.com/refund/"
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        request.httpMethod = "POST"
        let session = URLSession.shared
        let env = self.environment[selectedEnv.text!]
        let params = ["env": env!, "transaction_id": transctionID, "amount": self.amountTextField.text!, "type": "PTH", "body": "Refund the Amount"] as [String : Any]
        request.setBodyContent(parameters: params)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")

        let task = session.dataTask(with: request as URLRequest, completionHandler: {_, _, error -> Void in
            DispatchQueue.main.async {
                self.spinner.hide()
            }
            if error == nil {
                self.showAlert(errorMessage: "Refund intiated successfully")
            } else {
                self.showAlert(errorMessage: "Failed to intiate refund")
            }
        })
        task.resume()
    }
}

public extension NSMutableURLRequest {
    func setBodyContent(parameters: [String : Any]) {
        let parameterArray = parameters.map { (key, value) -> String in
            return "\(key)=\((value as AnyObject))"
        }
        httpBody = parameterArray.joined(separator: "&").data(using: String.Encoding.utf8)
    }
}
