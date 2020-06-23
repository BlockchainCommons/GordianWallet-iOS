//
//  NotificationDetailViewController.swift
//  FullyNoded2
//
//  Created by Peter on 22/06/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class NotificationDetailViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var buttonOutlet: UIButton!
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var icon: UIImageView!
    
    var notificationType = ""
    var backgroundTint = UIColor()
    var backgroundIcon = UIImage()
    var isAlert = Bool()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        textView.layer.cornerRadius = 8
        buttonOutlet.layer.cornerRadius = 8
        background.layer.cornerRadius = 8
        icon.image = backgroundIcon
        icon.tintColor = .white
        background.backgroundColor = backgroundTint
        setScene()
    }
    
    private func setScene() {
        switch notificationType {
        case "Refill":
            setRefill()
        default:
            break
        }
    }
    
    private func setRefill() {
        buttonOutlet.setTitle("refill keypool", for: .normal)
        buttonOutlet.addTarget(self, action: #selector(refillKeypool), for: .touchUpInside)
        titleLabel.text = "Refill Keypool"
        if isAlert {
            buttonOutlet.isEnabled = true
            buttonOutlet.setTitleColor(.systemTeal, for: .normal)
            textView.text = TextBlurbs.refillNowNotificationText()
        } else {
            buttonOutlet.isEnabled = false
            buttonOutlet.setTitleColor(.darkGray, for: .normal)
            textView.text = TextBlurbs.refillNotNeededNotificationText()
        }
    }
    
    @objc func refillKeypool() {
        print("refill keypool now")
        self.navigationController?.popToRootViewController(animated: true)
        NotificationCenter.default.post(name: .refillKeypool, object: nil, userInfo: nil)
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
