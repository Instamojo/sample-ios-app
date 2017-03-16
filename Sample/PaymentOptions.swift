//
//  PaymentOptions.swift
//  Instamojo
//
//  Created by Sukanya Raj on 15/03/17.
//  Copyright © 2017 Sukanya Raj. All rights reserved.
//

import UIKit
import Instamojo

class PaymentOptions : UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var cardNumberTextField: UITextField!
    @IBOutlet var expiryDateTextField: UITextField!
    @IBOutlet var cardHolderNameTextField: UITextField!
    @IBOutlet var cvvTextField: UITextField!
    @IBOutlet var payButton: UIButton!
    @IBOutlet var paymentOptionsListView: UITableView!
    
    var order : Order!
    
    var banks = [NetBankingBanks]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func pay(_ sender: UIButton) {
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let bank = banks[indexPath.row] as NetBankingBanks
        let bankName = bank.bankName
        cell.textLabel?.text = bankName
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return banks.count
    }
}
