//
//  PaymentOptions.swift
//  Instamojo
//
//  Created by Sukanya Raj on 15/03/17.
//  Copyright © 2017 Sukanya Raj. All rights reserved.
//

import UIKit
import Instamojo

class PaymentOptions : UIViewController, JuspayRequestCallBack {
    
    @IBOutlet var cardNumberTextField: UITextField!
    @IBOutlet var expiryDateTextField: UITextField!
    @IBOutlet var cardHolderNameTextField: UITextField!
    @IBOutlet var cvvTextField: UITextField!
    @IBOutlet var payButton: UIButton!
    var spinner: Spinner!
    
    @IBOutlet var expiryDatePicker: MonthYearPickerView!
    var order : Order!
    
    var banks = [NetBankingBanks]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner = Spinner(text : "Please Wait..")
        spinner.hide()
        self.view.addSubview(spinner)
        expiryDateTextField.inputView = expiryDatePicker
        expiryDatePicker.removeFromSuperview()
        expiryDatePicker.onDateSelected = { (month: Int, year: Int) in
            let date = String(format: Constants.DateFormat, month, year)
            self.expiryDateTextField.text = date
        }

        if order.netBankingOptions != nil {
            banks = order.netBankingOptions.banks
        }
    }
    
    @IBAction func pay(_ sender: UIButton) {
        //for card options payment
        let card = Card.init(cardHolderName: self.cardHolderNameTextField.text!, cardNumber: self.cardNumberTextField.text!, date: self.expiryDateTextField.text!, cvv: self.cvvTextField.text!, savedCard: false)
        if !card.isValidCard() {
            if !card.isValidCardHolderName() {
                self.showAlert(errorMessage: "Invalid Card Holder Name")
            }
            
            if !card.isValidCardNumber() {
                 self.showAlert(errorMessage: "Invalid Card Number")
            }
            
            if !card.isValidDate() {
                 self.showAlert(errorMessage: "Invalid Card Expiry Date")
            }
            
            if !card.isValidCVV() {
                 self.showAlert(errorMessage: "Invalid Card CVV")
            }
        }else{
            spinner.show()
            let request = Request(order: self.order, card: card, jusPayRequestCallBack: self)
            request.execute()
        }
    }
    
    func showAlert(errorMessage: String) {
        let alert = UIAlertController(title: "", message: errorMessage, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    //Call back recieved from juspay request to instamojo
    func onFinish(params: BrowserParams, error: String ) {
        if error.isEmpty {
            DispatchQueue.main.async {
                self.spinner.hide()
                Instamojo.makePayment(params: params)
            }
        }else{
            DispatchQueue.main.async {
                self.spinner.hide()
                let alert = UIAlertController(title: "Payment Status", message: "There seems to be some problem. Please choose a different payment options", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {(_) in
                    _ = self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

}
