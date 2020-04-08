//
//  DonateViewController.swift
//  FullyNoded2
//
//  Created by Peter on 11/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class DonateViewController: UIViewController {
    
    @IBOutlet var monthlyOutlet: UIButton!
    @IBOutlet var donateOutlet: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        monthlyOutlet.layer.cornerRadius = 8
        donateOutlet.layer.cornerRadius = 8
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func monthlySponsor(_ sender: Any) {
                
        UIApplication.shared.open(URL(string: "https://github.com/sponsors/BlockchainCommons")!) { (Bool) in }
        
    }
    
    @IBAction func btcpayDonate(_ sender: Any) {
        
        UIApplication.shared.open(URL(string: "https://btcpay.blockchaincommons.com")!) { (Bool) in }
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
