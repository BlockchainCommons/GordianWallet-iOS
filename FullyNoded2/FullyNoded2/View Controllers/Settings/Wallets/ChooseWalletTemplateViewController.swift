//
//  ChooseWalletTemplateViewController.swift
//  FullyNoded2
//
//  Created by Peter on 13/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class ChooseWalletTemplateViewController: UIViewController {
    
    var chooseTemplateDoneBlock : ((Bool) -> Void)?
    @IBOutlet var singleOutlet: UIButton!
    @IBOutlet var multiOutlet: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        singleOutlet.layer.cornerRadius = 18
        multiOutlet.layer.cornerRadius = 18
        
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func singleAction(_ sender: Any) {
        
        chooseTemplateDoneBlock!(true)
        self.dismiss(animated: true, completion: nil)
        print("single sig")
        
    }
    
    @IBAction func twoOfThreeAction(_ sender: Any) {
        
        chooseTemplateDoneBlock!(true)
        self.dismiss(animated: true, completion: nil)
        print("multi sig")
        
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
