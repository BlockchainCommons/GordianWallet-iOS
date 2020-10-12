//
//  TextBlurbs.swift
//  FullyNoded2
//
//  Created by Peter on 14/05/20.
//  Copyright © 2020 Blockchain Commons, LLC. All rights reserved.
//

class TextBlurbs {
    
    // MARK: - Random Home screen blurbs
    
    class func refillSingleSigWarningMessage(keysRemainging: Int) -> String {
        
        return "Your node only has \(keysRemainging) more public keys. We need to import more keys into your node at this point to ensure your node is able to verify this wallets balances and build psbt's for us."
        
    }
    
    class func refillMultiSigWarningMessage(keysRemainging: Int) -> String {
        
        return "Your node only has \(keysRemainging) more keys remaining in its keypool. We need to import more keys into your node at this point to ensure your node is able to verify this wallets balances, build psbt's for us and continue acting as a signer for your multisig transactions."
        
    }
    
    class func signPsbtMessage() -> String {
        
        return "We will attempt to process this psbt with your nodes current active account and sign it locally if it is not already signed. If the psbt is complete it will be returned to you as a raw transaction for verification and broadcasting, if it is incomplete you will be able to export it to another signer."
        
    }
    
    class func chooseColdcardDerivationToImport() -> String {
        
        return "You can choose either Native Segwit (BIP84, bech32 - bc1), Nested Segwit (BIP49, 3) or legacy (BIP44, 1) address types."
        
    }
    
    class func uploadAFileMessage() -> String {
        
        return "This button allows you to upload files via the iOS Files app. Currently we support psbt data files that comply with BIP174 and the Coldcard specific \"generic wallet export\" (single sig import) and \"multisig xpub export\"."
    }
    
    // MARK: - Account creation
    
    class func hotWalletInfo() -> String {
        
        return " A master seed is held by your device and your node holds a watch-only key set. This is a live account meaning you can spend from it at anytime from your device."
        
    }
    
    class func warmWalletInfo() -> String {
        
        return "One master seed is held by your device, the other two are held offline by you. We derive and import a key set into your node from one of your offline master seeds so that your node can be the second signer for this account. This adds a layer of security and redundancy in case you lost your node, device or offline seed storage. This a warm account as neither your device or your node can spend independently. In order to spend from this account your device will need to be connected to your node!"
    }
    
    class func coolWalletInfo() -> String {
        
        return "You will need to supply an xpub which will represent the devices master key. We will create two offline master seeds for you to backup, they will NOT be saved by the device. One of these master seeds will be used to derive a key set and import it into your node so that your node can be a single signer. Cool accounts are not capable of spending on their own! Cool accounts will build unsigned transactions and allow you to export them as PSBT's to other devices for signing. This is an ideal account type for collaborative multisig. You will always have the option to convert it to a warm account by adding a master seed in the form of BIP39 words to it."
    }
    
    class func coldWalletInfo() -> String {
        
        return "Cold accounts are single signature accounts where you will supply a master key xpub which is held by the device. The account will be purely watch-only and you will not be able to spend from it with this device. It will create unsigned transactions that can be exported to offline signers as PSBT's. You will always have the option to make it hot by adding a master seed to it in the form of BIP39 words."
    }
    
    class func customSeedInfo() -> String {
        
        return "This feature allows you to add your own BIP39 mnemonic as the device's master seed for the account you are about to create. This feature is only applicable to Hot and Warm accounts."
        
    }
    
    // MARK: - Sponsor Us text
    
    class func supportBlockchainCommons() -> String {
        
        return """
        Gordian Wallet is free, open-source software that is a project of Blockchain Commons. Our goal is to make it easier for beginners and experts alike to use Bitcoin in a secure, self-sovereign way, where you truly control your own digital assets.

        Creating this sort of tool is one of the primary mandates of Blockchain Commons, a "not-for-profit" social benefit corporation committed to open source & open development. And, we need your help! Our work is funded entirely by donations and collaborative partnerships with people like you. Every contribution will be spent on building open tools, technologies, and techniques that sustain and advance blockchain and internet security infrastructure and promote an open web. Your support can help to make this app and other important projects sustainable, as we continue building a self-sovereign future.

        You can either support us by becoming a GitHub sponsor, where GitHub is matching the first $5,000, or by contributing bitcoins through our BTCPay server.
        """
    }
    
    // MARK: - Account created successfully
    
    class func multiSigWalletCreatedSuccess() -> String {
        
        return "In order to recover your account there is some information you ought to save securely.\n\nYou will be presented with an \"Account Map\" QR code (the account public keys) and two 12 word seed phrases.\n\nIt is recommended you store the seed phrases in different locations, if they are stored together a thief may be able to access your funds.\n\nSaving both the \"Account Map QR\" and the two seed phrase's will ensure you can fully recover your multi-signature account if this device were to be lost or stolen."
    }
    
    class func singleSigWalletCreatedSuccess() -> String {
        
        return "In order to ensure you can recover your account there is some information you ought to record securely.\n\nYou will be presented with an \"Account Map\" QR code and a 12 word seed phrase.\n\nYou should make multiple backups of each and store them securely."
    }
    
    class func accountMapMultiSigCreated() -> String {
        
        return """
        YOU WILL NEED THIS QR TO RECOVER A MULTI-SIG WALLET! Make many copies of it and save it in many physical and digital places!

        It holds your wallets PUBLIC KEYS, and can not be used to spend funds! In order to spend from it you will need the seed words too.
        """
    }
    
    class func accountMapSingleSigCreated() -> String {
     
        return """
        The Account Map QR ***ONLY holds your wallets PUBLIC KEYS***, and can not be used to spend funds!
        
        ***In order to spend from it you will NEED the seed words too!***
        """
        
    }
    
    class func coldCardMultiSigCreatedSeedWarning() -> String {
        
        return """
        On the next two screens we will display two master seeds.

        You *MUST* save them seperately from each other! *THEY ARE REQUIRED* to fully recover a multi-signature account.
        
        The first seed represents your offline seed, and is only needed if you ever lose your Coldcard or this device. These words **WILL BE DELETED FOREVER** from this device once you tap the "I saved them" button!
        
        The second master seed is your device's seed words, these words will be needed to fully recover this multi-sig wallet if you lose your Coldcard seed or backup seed.
        
        At a minimum we recommend writing these words down on water proof paper with a permanent marker, ideally engrave them on titanium if you are going to store larger amounts.
        """
    }
    
    class func multiSigCreatedSeedWarning() -> String {
        
        return """
        On the next two screens we will display two master seeds.

        You *MUST* save them seperately from each other! *THEY ARE REQUIRED* to fully recover a multi-signature account.
        
        The first one represents your nodes master seed, it is important to note your node does not hold this seed, it only holds a key set that is derived from this seed. If you lose your node you will want to be able to use these words to recover your nodes private keys.
        
        The second master seed is your offline seed words, these words will be needed to fully recover this multi-sig wallet.
        
        These words **WILL BE DELETED FOREVER** from this device once you tap the "I saved them" button!

        At a minimum we recommend writing these words down on water proof paper with a permanent marker, ideally engrave them on titanium if you are going to store larger amounts.
        """
    }
    
    class func singleSigCreatedSeedWarning() -> String {
        
        return """
        On the next screen we will display your devices seed as a 12 word BIP39 mnemonic.

        You should write these 12 words down and save them as they are REQUIRED to recover this account!
        
        At a minimum we recommend writing these words down on water proof paper with a permanent marker.
        """
    }
    
    class func warnSeedWordsWillDisappear() -> String {
        
        return "Once you tap \"Yes, I saved them\" the backup words will be gone forever! If you tap \"Oops, I forgot\" we will show them to you again so you may save them."
        
    }
    
    // MARK: - Account recovery and creating accounts with user supplied xpubs
    
    class func invalidExtendedKeyWarning() -> String {
        return "That is not a valid xpub or tpub"
    }
    
    class func onlyExtendedKeysHereWarning() -> String {
        
        return "This option is only for creating watch-only wallets with user supplied extended keys. If you would like to supply a seed tap the \"add BIP39 words\" button below."
    }
    
    class func invalidPathWarning() -> String {
        
        return "You need to paste in an xpub with is path and master key fingerprint in the following format:\n\n[UTYR63H/84'/0'/0']xpub7dk20b5bs4..."
    }
    
    class func invalidExtendedKeyWithPathWarning() -> String {
        
        return "You need to paste in an xpub with is path and master key fingerprint in the following format:\n\n[UTYR63H/84'/0'/0']xpub7dk20b5bs4..."
    }
    
    class func unsupportedMultiSigPath() -> String {
        
        return "Gordian Wallet only accepts BIP48 aka WIP48 derivation scheme for importing multisig wallets with xpubs only for now."
    }
    
    class func invalidRecoveryFormat() -> String {
        
        return "You need to paste in an xpub with is path and master key fingerprint in the following format:\n\n[UTYR63H/84'/0'/0']xpub7dk20b5bs4..."
    }
    
    // MARK: - Introduction blurbs...
    
    class func introductionText() -> String {
        
        return """
        Thanks for trying out Gordian Wallet!

        You will be using a state-of-the-art mobile wallet to connect to the Bitcoin network in no time, accessing a full node of your choice.

        But first there are a few things you should know ...

        We appreciate your attention and patience!
        """
    }
    
    class func whatIsFN2Text() -> String {
        
        return """
        Gordian Wallet is a professional mobile wallet built using the most up-to-date technologies for Bitcoin. It's focused on three goals that together demonstrate some of the best practices for modern mobile-wallet design:

        1. **Self-sovereign Interactions.** Classic mobile wallets usually talked to a full node chosen by the wallet developer and owned/controlled by someone else. Gordian Wallet instead allows you to choose a full node, either one created using a setup process such as #BitcoinStandup and run by yourself, or a service offered by a provider that you select: self-sovereign means you get to decide. (You can use Blockchain Commons' full-node server for beta testing, but you should migrate to a protected server for real money transactions.)

        2. **Protected Communications.** All of the communications in Gordian Wallet are protected by the latest version of Tor, which provides two-way authentication of both the server and your wallet. Unlike traditional use of the soon to be deprecated SPV protocol, which reveals that you're accessing the Bitcoin network, Tor simply shows that you're engaging in private onion communications. It's safer when you're in a hostile state, and it's safer in your local coffee shop.

        3. **Multi-sig Protections.** Finally, Gordian Wallet ensures that your private keys are protected from the most common adversary: loss. Its 2-of-3 multi-sig system leaves one key on the server, one on your mobile wallet, and one in safe off-line storage. If you lose your phone or your server, you can still rebuild from the other two. (The Blockchain Commons #SmartCustody system talks more about how to protect off-line keys.)

        Gordian Wallet is intended for a sophisticated power user. It's a leading-edge platform that experiments with modern Bitcoin technologies to create a powerful new architecture with features not found in other mobile wallets. It's intended as a professional wallet for your use and also as a demonstration of functionality that other companies can integrate into their own apps as an open source reference implementation of functionality.

        Even more cutting-edge technology is planned for the future, including collaborative custody models, airgapped technologies such as Blockchain Commons' #LetheKit for offline signing using QR codes, and methodologies for social-key recovery.
        """
    }
    
    class func howToSupportFN2() -> String {
        
        return """
        Gordian Wallet is a project of Blockchain Commons. We are proudly a "not-for-profit" social benefit corporation committed to open source & open development. Our work is focused on building open tools, technologies, and techniques that sustain and advance blockchain and internet security infrastructure and promote an open web. It's funded entirely by donations and collaborative partnerships with people like you.

        For the Gordian Wallet source code and detailed information about how the app works, please visit the GitHub repo.

        If you find this project useful, and would like to learn more about Blockchain Commons, click the Blockchain Commons logo within the app. You can become a Blockchain Commons patron and support projects like this!
        """
    }
    
    class func howToUseFN2Text() -> String {
        
        return """
        Ready to get started?

        Connect to your node by scanning the QuickConnect QR code that your node software produces. The app will then do all the hard work for you. Supported node software includes StandUp.app (MacOS), BTCPay, MyNode, RaspiBlitz, and Nodl with more to come!

        Once Gordian Wallet connected, using it is straightforward:

        * To create a Bitcoin invoice just tap the "In" button.
        * To spend Bitcoin just tap the "Out" button.
        """
    }
    
    class func isFN2SecureText() -> String {
        
        return """
        Gordian Wallet runs a Tor node which it uses to connect to your nodes V3 hidden service over the onion network. This way you can privately and securely control your nodes wallet functionality remotely from anywhere in the world, allowing you to keep your node completely behind a firewall with no port forwarding required. The app uses a lot of security minded features to avoid any sensitive info being recorded to your devices memory regarding the Tor traffic. Clearnet traffic is strictly disabled, the Tor config settings excludes exit nodes from your Tor circuit meaning it will only ever interact with the Tor network.

        Gordian Wallet uses powerful encryption to secure your your nodes hidden service urls and private keys. Initially a private key is created which is stored on your devices keychain which is itself encrypted. That private key is used to decrypt/encrypt the apps sensitive data. Whenever your device goes into the background all the apps data becomes encrypted yet again. No sensitive info is ever stored unencrypted or transmitted over the internet in clear text. All Tor traffic is highly encrypted by default.

        Gordian Wallet utilizes the latest generation of hidden services and allows you to take advantage of Tor V3 authentication, meaning your device is capable of producing a private/public key offline where you may upload the public to your node to ensure that your device is the only device in the world that can access your node EVEN IF an attacker managed to get your nodes hidden service url. This means of authentication is particularly handy if you want to share your node with trusted others, ensuring only they have access. This is possible because you as the user never have access to the private key used for authentication, so even if users share their public keys with an attacker it would be useless to them. To be clear the way it works is Gordian Wallet will create the ultra secret private key, encrypt it and store it locally, it then get decrypted when the Tor node starts up, whenever your app goes into the background the private key is deleted from your Tor config, the file the private key is saved on is also maximally protected by native iOS encryption on top of a secondary layer of encryption we give it, you as theuser will never see or have access to the private key and without that private key no device or attacker can possibly get access to your nodes hidden service. Of course there may be attack vectors we are not aware of and it is important you do your own research and look at the codebase if you are curious.
        """
    }
    
    class func licenseAndDisclaimerText() -> String {
        
        return """
        Please read and accept the terms of our disclaimer:

        The use of Gordian Wallet is under the "BSD 2-Clause Plus Patent License" (https://spdx.org/licenses/BSD-2-Clause-Patent.html). Copyright © 2019 BlockchainCommons. All rights reserved. With the disclaimer: THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
        """
    }
    
    class func twoFactorAuthExplainerText() -> String {
        
        return """
        Gordian Wallet uses the "Sign in with Apple" tool for 2FA (two-factor authentication) purposes. It saves your Apple ID username to the device's Secure Enclave upon a successful sign-in.

        Then, whenever you broadcast a transaction or expose a private key/seed, Gordian Wallet will prompt you to authenticate again, ensuring that only you can spend your bitcoins. Depending on your device's settings, you will either be prompted with biometrics or manual password entry for your Apple ID.

        Blockchain Commons and Gordian Wallet never share any data with any third party ever. The only server the app connects to is your specified node, and only using Tor. "Sign in with Apple" is simply a secure way of ensuring no one else can spend your funds.
        """
    }
    
    // MARK: - Wallet Tools Info
    
    class func rescanInfoText() -> String {
        
        return "This tool allows you to rescan the blockchain for your current account. This is useful if you have just recovered an account or imported an account and no balance is showing yet."
    }
    
    class func sweepToInfoText() -> String {
        
        return "This tool allows you to sweep all your current account funds to another account."
    }
    
    class func refillKeypoolText() -> String {
        
        return "This tools allows you to refill your nodes keypool."
    }
    
    class func addSignerText() -> String {
        
        return "This tool allows you to add a master seed in the form of a BIP39 mnemonic which can sign for your current account."
    }
    
    class func backupInfoText() -> String {
        
        return "This tool allows you to view and export your current account info, including your device's seed, your account xpub's and the Account Map."
    }
    
    class func viewUtxosText() -> String {
        
        return "This tool allows you to view your UTXO's."
    }
    
    class func exportKeysText() -> String {
        
        return "This tool allows you to view and export your addresses, public keys, and scriptpubkey as well displaying the derivation path for each."
    }
    
    //MARK: - Notification Center Detail
    
    class func refillNowNotificationText() -> String {
        
        return """
        When your account is created FN2 imports 0 to 2500 receiving keys and 2500 change keys so that your node can watch for transactions, balances, and build psbt's using utxo's those keys are associated with.
        
        It is best practice to never reuse keys, therefore once you reach a key index that is 100 or less away from your final key you will be notified that it is time to refill your keypool.
        
        You will need to use your node's seed words to refill the keypool for Warm accounts created with FN2. The reason is we do not save your node's seed and need to use it to maintain your node's signing ability.
        
        It can take up to 30 seconds to complete the refill process. Upon a successful refil the UI on the "Accounts" view will dynamically update to show the updated range of keys that exist on your node.
        """
    }
    
    class func refillNotNeededNotificationText() -> String {
        
        return """
        When your account is created FN2 imports 0 to 2500 receiving keys and 2500 change keys so that your node can watch for transactions, balances, and build psbt's using utxo's those keys are associated with.
        
        It is best practice to never reuse keys, therefore once you reach a key index that is 100 or less away from your final key you will be notified that it is time to refill your keypool.
        
        Currently you are over 100 keys away from needing to refill your keypool, no action is needed, you can refill your keypool at any time via "Accounts" > "Tools" > "Refill keypool".
        """
    }
}
