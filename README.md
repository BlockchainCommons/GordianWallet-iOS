# FullyNoded 2

## Status

*FullyNoded 2* is currently under active development and in the early testing phase. It should only be used on testnet for now.

*FullyNoded 2* is designed to work with the [MacOS StandUp.app](https://github.com/BlockchainCommons/Bitcoin-StandUp-MacOS) and [Linux scripts](https://github.com/BlockchainCommons/Bitcoin-StandUp-Scripts), but will work with any properly configured Bitcoin Core 0.19.0.1 node with a hidden service controlling `rpcport` via localhost. Supporting nodes are [Nodl](https://www.nodl.it/), [BTCPayServer](https://btcpayserver.org) and [RaspiBlitz](https://github.com/rootzoll/raspiblitz), these nodes can be connected by clicking a link or scanning a qr code. Please refer to their telegram groups for simple instructions: 

- [Nodl Telegram](https://t.me/nodl_support)
- [BTCPayServer](https://t.me/btcpayserver)
- [RaspiBlitz Telegram](https://t.me/raspiblitz)

## Testflight

We have a public link available for beta testing [here](https://testflight.apple.com/join/OQHyL0a8), please only use the app on testnet. Please do share crash reports and give feedback. Want a feature added? Tell us about it.

### Initial Setup

Upon on initial use the user may choose to connect to their own node by scanning a [QuickConnect QR](https://github.com/BlockchainCommons/Bitcoin-Standup#quick-connect-url-using-btcstandup) or a testnet node we are currently utilizing for development purposes by tapping the "don't have a node?" button:

<img src="https://github.com/BlockchainCommons/FullyNoded-2/blob/master/Images/quickConnect.PNG" alt="" width="250"/>

Once you are connected to a node you may go to the "Wallets" tab and create either a Single-Sig, Multi-Sig or import a wallet (recovery is under development):

<img src="https://github.com/BlockchainCommons/FullyNoded-2/blob/master/Images/createWallet.PNG" alt="" width="250"/>

After creating a wallet you will see it on the "Wallets" page:

<img src="https://github.com/BlockchainCommons/FullyNoded-2/blob/master/Images/wallets.PNG" alt="" width="250"/>

You can activate/deactivate wallets by toggling them, when you have an active wallet your home screen will look like this:

<img src="https://github.com/BlockchainCommons/FullyNoded-2/blob/master/Images/home.PNG" alt="" width="250"/>

You may expand the cells to show more info about your Tor connection and Wallet by tapping the info buttons:

<img src="https://github.com/BlockchainCommons/FullyNoded-2/blob/master/Images/expanded.PNG" alt="" width="250"/>

### Everyday use

Currently the app is fully capable of creating and locally signing PSBT's with either multisig or single signature wallets. It also builds unsigned PSBT's for watch-only wallets which can be passed to external signers such as [Hermit](https://github.com/unchained-capital/hermit/blob/master/hermit) or [Coldcard](https://coldcardwallet.com).

<img src="https://github.com/BlockchainCommons/FullyNoded-2/blob/master/Images/unsigned1.PNG" alt="" width="250"/>

*FullyNoded 2* transaction flow: 

- creates the psbt with your node
- signs the psbt with your node (if it can)
- signs the psbt locally on your device (if it can)
- the transaction is then decoded and analyzed, each input/output is listed, identifiying change outputs and the mining fee
- the user may tap each input/output and the app will make the `getaddressinfo` rpc command to your node for the respective address so that you may confirm whether or not the address is yours and the utxo is the intended one
- if the transaction is fully signed you can broadcast by tapping the play button
- if the transaction is still partially signed or unsigned at all you may export it for external signing (it will show blue), currently *FullyNoded 2* will export the psbt in raw data fromat which is fully compatible with Coldcard Wallet

<img src="https://github.com/BlockchainCommons/FullyNoded-2/blob/master/Images/unsigned2.PNG" alt="" width="250"/>

The app also offers coin control, fee optimization, batching and other useful tools for verifying keys and exporting backups.

### Single-Signature

Single signature wallets take a unique approach in that a new wallet is created on your node with private keys disabled and avoid address reuse set to true. Once the wallet creation is confirmed on your node the app will utilize the LibWally-Swift libary in conjunction with Apple's native cryptographically secure random number generator to generate a seed locally. The seed is encrypted and stored on the device only. The entropy is converted into a 12 word BIP39 recovery phrase, the app then utilizes the `importmulti` rpc command to derive 2,000 public keys from the seeds BIP84 xpub. This allows your node to handle all the transaction building with the rpc command `walletcreatefundedpsbt` which handles coin selection, fee optimization and avoids address reuse. The app will create the unsinged psbt with your node and then signs the psbt locally so that your private keys are *never* broadcasted over Tor.

### Multi-Signature

By default *FullyNoded 2* will create a 2 of 3 mutlisignature wallet whereby all three seeds are created locally. One seed is converted to BIP39 words for the user to record securely for recovery purposes and then deleted forever from the device. The app will then create a wallet on your node and utilizes the `importmulti` command to import 2,000 BIP84 private keys to your nodes wallet so that it may sign for one of the two required signatures. The third seed is saved locally to your device as a BIP39 mnemonic. When it comes to spending again we utilize `walletcreatefundedpsbt` on your node to handle coin selection, and fee optimization. Your node will then sign the psbt and pass it to the app at which time the app will sign for the second signature locally. With this set up a user may lose either their node, device or the BIP39 back up recovery words and still be able to spend their bitcoin. In a future release the app will allow multiple levels of security including 2fa and wallet.dat encryption which would mean even if an attacker got hold of your device they would *also* need your decryption password to spend funds.

### Importing a Wallet

You may import any type of [descriptor](https://github.com/bitcoin/bitcoin/blob/master/doc/descriptors.md). Future releases will add the ability to import other things too. If you want to test this functionality you can either copy one of your descriptors from your exisiting wallets or visit this [link](https://github.com/bitcoin/bitcoin/blob/master/doc/descriptors.md) and learn how to convert your xpub/xprv or multisig wallet into a descriptor. FullyNoded 1 is able to export descriptors and will convert any extended key you import into it into a descriptor that can be used in *FullyNoded 2*.

The reason we use descriptors are because they are human readable, unambigous bits of text which make storing complex wallet meta data as easy as saving a QR code. They are utilized by Bitcoin Core. Entire complex custom derived HD multisig wallets can be fully recovered with a single command using your own node, this is superior to storing indivdual keys, addresses and redeem scripts.

### Exporting a Wallet

*FullyNoded 2* allows you to export the seed which is stored on your device at anytime in the form of a 12 word BIP39 mnemonic, a public key descriptor, private key descriptor and even the verbatim rpc command `importmulti` which can be copied and pasted into your nodes terminal to recover your wallets seed.

<img src="https://github.com/BlockchainCommons/FullyNoded-2/blob/master/Images/export1.PNG" alt="" width="250"/>

<img src="https://github.com/BlockchainCommons/FullyNoded-2/blob/master/Images/export2.PNG" alt="" width="250"/>

### Wishlist

- [ ] Wallet Functions
  - [x] Offline PSBT signing
  - [x] Offline raw transaction signing
  - [x] Spend and Receive
  - [x] Segwit
  - [x] Non-custodial
  - [ ] Coin Control (work in progress)
  - [x] BIP44
  - [x] BIP84
  - [x] BIP49
  - [x] BIP32
  - [x] BIP21
  - [x] Custom mining fee
  - [x] Multisig
  - [x] Cold storage
  - [x] Multiwalletrpc
  
- [ ] Security
  - [x] Seed created with Apple's cryptographically secure random number generator
  - [x] Seed encrypted with a private key stored on the devices keychain which is itself encrypted
  - [x] Seed encrypted with native iOS code
  - [x] Tor V3 Authentication
  - [ ] Passphrase support
  - [ ] Wallet.dat encryption (work in progress)
  - [ ] Disable all networking before importing/exporting seed 
  - [ ] Automated Tor authentication
  - [ ] 2FA
  - [ ] Add local authentication via biometrics/pin/password (work in progress)
 
- [ ] Compatible Nodes
  - [x] Your own Bitcoin Core node
  - [x] MacOS - [StandUp.app](https://github.com/BlockchainCommons/Bitcoin-StandUp-MacOS)
  - [x] Linux - [StandUp.sh](https://github.com/BlockchainCommons/Bitcoin-StandUp-Scripts)
  - [x] Nodl
  - [x] myNode
  - [x] BTCPayServer
  - [x] RaspiBlitz
  - [ ] Wasabi
  - [ ] CasaHodl

### Requirements

- iOS 13
- a Bitcoin Core full-node v0.19.0.1 (at minimum) which is running on Tor with `rpcport` exposed to a Tor V3 hidden service

### Build From Source

##### Install Brew

Run `brew --version` in a terminal, if you get a valid response you have brew installed already, if not:

```cd /usr/local
mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
```
Wait for bew to finish.

##### Install carthage

Follow these [instructions](https://brewinstall.org/install-carthage-on-mac-with-brew/)

##### Install Tor.Framework Dependencies

`brew install automake autoconf libtool gettext`

##### Install XCode

- Install [Xcode](https://itunes.apple.com/id/app/xcode/id497799835?mt=12)
- You will need a free Apple developer account [create one here](https://developer.apple.com/programs/enroll/)
- In XCode, click "XCode" -> "preferences" -> "Accounts" -> add your github account
- Go to the [repo](https://github.com/BlockchainCommons/FullyNoded-2) click `Clone and Download` -> `Open in XCode`
- Open Terminal
- `cd <into the project>`
- run `carthage update --platform iOS` and wait for carthage to finish

The app should now run in XCode.

### Principal Architect
- Christopher Allen [@ChristopherA](https://github.com/@ChristopherA) \<ChristopherA@LifeWithAlacrity.com\>

### Project Lead
- Peter Denton [@Fonta1n3](https://github.com/Fonta1n3) \<fonta1n3@protonmail.com\>
- GPG Fingerprint: 3B37 97FA 0AE8 4BE5 B440  6591 8564 01D7 121C 32FC 

### Authors
- Add your name here by getting involved, first step is to check out our [contributing section](https://github.com/BlockchainCommons/FullyNoded-2#contributing).

### Reporting a Vulnerability

To report security issues send an email to ChristopherA@LifeWithAlacrity.com (not for support).

The following keys may be used to communicate sensitive information to developers:

| Name              | Fingerprint                                        |
| ----------------- | -------------------------------------------------- |
| Christopher Allen | FDFE 14A5 4ECB 30FC 5D22  74EF F8D3 6C91 3574 05ED |

You can import a key by running the following command with that individual’s fingerprint: `gpg --recv-keys "<fingerprint>"` Ensure that you put quotes around fingerprints that contain spaces.

### Built with
- [Tor.framework](https://github.com/iCepa/Tor.framework) by the [iCepa project](https://github.com/iCepa) - for communicating with your nodes hidden service
- [LibWally-Swift](https://github.com/blockchain/libwally-swift) built by @sjors - for BIP39 mnemonic creation and HD key derivation
- [Base32](https://github.com/norio-nomura/Base32/blob/master/Sources/Base32) built by @norio-nomura - for Tor V3 authentication key encoding
- [Keychain-Swift](https://github.com/evgenyneu/keychain-swift) built by @evgenyneu for securely storing sensitive data on your devices keychain

### Copyright & License

This code in this repository is Copyright © 2019 by Blockchain Commons, LLC, and is [licensed](https://github.com/BlockchainCommons/FullyNoded-2/blob/master/LICENSE) under the [spdx:BSD-2-Clause Plus Patent License](https://spdx.org/licenses/BSD-2-Clause-Patent.html).

### Contributing

We encourage public contributions through issues and pull-requests! Please review [CONTRIBUTING.md](https://github.com/BlockchainCommons/FullyNoded-2/blob/master/CONTRIBUTING.md) for details on our development process. All contributions to this repository require a GPG signed [Contributor License Agreement](https://github.com/BlockchainCommons/FullyNoded-2/blob/master/CLA.md).


