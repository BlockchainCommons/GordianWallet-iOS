//
//  IsFN2SecureViewController.swift
//  FullyNoded2
//
//  Created by Peter on 25/03/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

import UIKit

class IsFN2SecureViewController: UIViewController, UITextViewDelegate, UINavigationControllerDelegate {

    @IBOutlet var textView: UITextView!
    @IBOutlet var nextOutlet: UIButton!
    @IBOutlet var titleLabel: UILabel!
    
    let torLink = "https://www.torproject.org"
    let hiddenServiceLink = "https://blog.torproject.org/tors-fall-harvest-next-generation-onion-services"
    let authLink = "https://matt.traudt.xyz/p/FgbdRTFr.html"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.delegate = self
        setTitleView()
        nextOutlet.layer.cornerRadius = 8
        titleLabel.adjustsFontSizeToFitWidth = true
        textView.delegate = self
        
        textView.text = """
        FullyNoded 2 runs a Tor node which it uses to connect to your nodes V3 hidden service over the onion network. This way you can privately and securely control your nodes wallet functionality remotely from anywhere in the world, allowing you to keep your node completely behind a firewall with no port forwarding required. The app uses a lot of security minded features to avoid any sensitive info being recorded to your devices memory regarding the Tor traffic. Clearnet traffic is strictly disabled, the Tor config settings excludes exit nodes from your Tor circuit meaning it will only ever interact with the Tor network.

        FullyNoded 2 uses powerful encryption to secure your your nodes hidden service urls and private keys. Initially a private key is created which is stored on your devices keychain which is itself encrypted. That private key is used to decrypt/encrypt the apps sensitive data. Whenever your device goes into the background all the apps data becomes encrypted yet again. No sensitive info is ever stored unencrypted or transmitted over the internet in clear text. All Tor traffic is highly encrypted by default.

        FullyNoded 2 utilizes the latest generation of hidden services and allows you to take advantage of Tor V3 authentication, meaning your device is capable of producing a private/public key offline where you may upload the public to your node to ensure that your device is the only device in the world that can access your node EVEN IF an attacker managed to get your nodes hidden service url. This means of authentication is particularly handy if you want to share your node with trusted others, ensuring only they have access. This is possible because you as the user never have access to the private key used for authentication, so even if users share their public keys with an attacker it would be useless to them. To be clear the way it works is FullyNoded will create the ultra secret private key, encrypt it and store it locally, it then get decrypted when the Tor node starts up, whenever your app goes into the background the private key is deleted from your Tor config, the file the private key is saved on is also maximally protected by native iOS encryption on top of a secondary layer of encryption we give it, you as theuser will never see or have access to the private key and without that private key no device or attacker can possibly get access to your nodes hidden service. Of course there may be attack vectors we are not aware of and it is important you do your own research and look at the codebase if you are curious.
        """
        
        textView.addHyperLinksToText(originalText: textView.text, hyperLinks: ["Tor": torLink, "V3 hidden service": hiddenServiceLink, "Tor V3 authentication": authLink])
        
    }
    
    private func setTitleView() {
        
        let imageView = UIImageView(image: UIImage(named: "1024.jpg"))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        imageView.frame = titleView.bounds
        imageView.isUserInteractionEnabled = true
        titleView.addSubview(imageView)
        self.navigationItem.titleView = titleView
        
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if (URL.absoluteString == torLink) || (URL.absoluteString == hiddenServiceLink) || (URL.absoluteString == authLink) {
            UIApplication.shared.open(URL) { (Bool) in

            }
        }
        return false
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.performSegue(withIdentifier: "next5", sender: self)
        }
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
