//
//  NotificationCenterViewController.swift
//  FullyNoded2
//
//  Created by Peter on 22/06/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class NotificationCenterViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var notificationTable: UITableView!
    var notificationDict:[String:Any]?

    override func viewDidLoad() {
        super.viewDidLoad()
        notificationTable.delegate = self
        notificationTable.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadData()
    }
    
    private func loadData() {
        getActiveWalletNow { [unowned vc = self] (wallet, error) in
            if wallet != nil {
                vc.checkWalletStatus(wallet: wallet!)
            } else {
                showAlert(vc: vc, title: "No active wallet", message: "In order to check the status of your wallet we need yo to activate a wallet.")
            }
        }
    }
    
    private func checkWalletStatus(wallet: WalletStruct) {
        print("checkwalletstatus")
        WalletStatus.getStatus(wallet: wallet) { [unowned vc = self] dict in
            vc.notificationDict = dict
            vc.notificationTable.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if notificationDict != nil {
            return refillCell(indexPath)
        } else {
            return UITableViewCell()
        }
    }
    
    private func refillCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = notificationCell(indexPath)
        let background = cell.viewWithTag(1)!
        let icon = cell.viewWithTag(2) as! UIImageView
        let label = cell.viewWithTag(3) as! UILabel
        background.layer.cornerRadius = 8
        icon.tintColor = .white
        let checkmarkImage = UIImage(systemName: "checkmark.circle")!
        let alertImage = UIImage(systemName: "exclamationmark.circle")!
        let shouldRefill = notificationDict?["shouldRefill"] as? Bool ?? false
        label.text = "Refill keypool"
        if shouldRefill {
            icon.image = alertImage
            background.backgroundColor = .systemRed
        } else {
            icon.image = checkmarkImage
            background.backgroundColor = .systemGreen
        }
        return cell
    }
    
    private func notificationCell(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = notificationTable.dequeueReusableCell(withIdentifier: "notificationCell", for: indexPath)
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        goToDetailView()
    }
    
    private func goToDetailView() {
        DispatchQueue.main.async { [unowned vc = self] in
            vc.performSegue(withIdentifier: "showNotificationDetail", sender: vc)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showNotificationDetail" {
            if let vc = segue.destination as? NotificationDetailViewController {
                
               guard let shouldRefill = notificationDict?["shouldRefill"] as? Bool else {
                    vc.backgroundIcon = UIImage(systemName: "checkmark.circle")!
                    vc.backgroundTint = .systemGreen
                    vc.isAlert = false
                    vc.notificationType = "Refill"
                    
                    return
                }
                
                if shouldRefill {
                    vc.backgroundIcon = UIImage(systemName: "exclamationmark.circle")!
                    vc.backgroundTint = .systemRed
                } else {
                    vc.backgroundIcon = UIImage(systemName: "checkmark.circle")!
                    vc.backgroundTint = .systemGreen
                }
                
                vc.isAlert = shouldRefill
                vc.notificationType = "Refill"
            }
        }
    }
    

}
