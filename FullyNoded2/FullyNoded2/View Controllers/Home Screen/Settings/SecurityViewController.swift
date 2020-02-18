//
//  SecurityViewController.swift
//  FullyNoded2
//
//  Created by Peter on 17/02/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit
import KeychainSwift

class SecurityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let keychain = KeychainSwift()
    @IBOutlet var table: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func close(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "securityCell", for: indexPath)
        cell.selectionStyle = .none
        cell.textLabel?.textColor = .lightGray
        
        if keychain.get("UnlockPassword") != nil {
            
            cell.textLabel?.text = "Reset Password"
            
        } else {
            
            cell.textLabel?.text = "Set Password"
            
        }
        
        return cell
        
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
