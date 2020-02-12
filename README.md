# FullyNoded 2

## Status

FullyNoded 2 is currently under active development and in the early testing phase. It should only be used on testnet for now.

FullyNoded 2 is designed to work with the [MacOS StandUp.app](https://github.com/BlockchainCommons/Bitcoin-Standup/tree/master/StandUp) and [Linux scripts](https://github.com/BlockchainCommons/Bitcoin-Standup/tree/master/LinuxScript), but will work with any properly configured Bitcoin Core 0.19.0.1 node with a hidden service controlling `rpcport` via localhost. Supporting nodes are [Nodl](https://www.nodl.it/), [BTCPayServer](https://btcpayserver.org) and [RaspiBlitz](https://github.com/rootzoll/raspiblitz), these nodes can be connected by clicking a link or scanning a qr code. Please refer to their telegram groups for simple instructions: 

- [Nodl Telegram](https://t.me/nodl_support)
- [BTCPayServer](https://t.me/btcpayserver)
- [RaspiBlitz Telegram](https://t.me/raspiblitz)

## Testflight

We have a public link available for beta testing [here at this link](https://testflight.apple.com/join/OQHyL0a8), please bare in mind the app may change drastically and may not be backward compatible, please only use the app on testnet.

### Initial Setup

Upon on initial use the user may choose to connect to their own node or a testnet node we are currently utilzing for development purposes. Once you are connected to a node you may go to the "Wallets" tab and create either a Single-Sig, Multi-Sig or Custom wallet.

### Single-Signature

Single signature wallets take a unique approach in that a new wallet is created on your node with private keys disabled and avoid address reuse set to true. Once the wallet creation is confirmed on your node the app will utilize the LibWally-Swift libary in conjunction with Apple's native cryptographically secure random number generator to generate a seed locally. The seed is encrypted and stored on the device only. The entropy is converted into a 12 word BIP39 recovery phrase, the app then utilizes the `importmulti` rpc command to derive 2,000 public keys from the seeds BIP84 xpub. This allows your node to handle all the transaction building with the rpc command `walletcreatefundedpsbt` which handles coin selection, fee optimization and avoids address reuse. The app will create the unsinged psbt with your node and then signs the psbt locally so that your private keys are *never* broadcasted over Tor.

### Multi-Signature

By default FullyNoded 2 will create a 2 of 3 mutlisignature wallet whereby all three seeds are created locally. One seed is converted to BIP39 words for the user to record securely for recovery purposes and then deleted forever from the device. The app will then create a wallet on your node and utilizes the `importmulti` command to import 2,000 BIP84 private keys to your nodes wallet so that it may sign for one of the two required signatures. The third seed is saved locally to your device as a BIP39 mnemonic. When it comes to spending again we utilize `walletcreatefundedpsbt` on your node to handle coin selection, and fee optimization. Your node will then sign the psbt and pass it to the app at which time the app will sign for the second signature locally. With this set up a user may lose either their node, device or the BIP39 back up recovery words and still be able to spend their bitcoin. In a future release the app will allow multiple levels of security including 2fa and wallet.dat encryption which would mean even if an attacker got hold of your device they would *also* need your decryption password to spend funds.

### Custom

At present this feature is being utilized for testing purposes only. The idea being we want to allow purely watch-only wallets for deep cold storage whilst also allwoing users to sign PSBT's offline, or pass unsigned PSBT's to other signers. For now this is not ready for active use but will be in the near future. If you want to test it you can make any wallet cold in the wallets view by tapping the cold button or by importing a public key descriptor from one of your exisiting wallets.

### Wishlist

- [ ] Wallet Functions
  - [x] Spend and Receive
  - [x] Segwit
  - [x] Non-custodial
  - [ ] Coin Control
  - [ ] BIP44
  - [x] BIP84
  - [ ] BIP49
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
  - [ ] Wallet.dat encryption
  - [ ] Disable all networking before importing/exporting seed 
  - [ ] Automated Tor authentication
  - [ ] 2FA
  - [ ] Add local authentication via biometrics/pin/password
 
- [ ] Compatible Nodes
  - [x] Your own Bitcoin Core node
  - [x] MacOS - [StandUp.app](https://github.com/BlockchainCommons/Bitcoin-Standup/tree/master/StandUp)
  - [x] Linux - [StandUp.sh](https://github.com/BlockchainCommons/Bitcoin-Standup/tree/master/LinuxScript)
  - [x] Nodl
  - [x] myNode
  - [x] BTCPayServer
  - [x] RaspiBlitz
  - [ ] Wasabi
  - [ ] CasaHodl

### Everyday use

Currently the app is fully capable of creating and signing PSBT's with either multisig or single signature wallets. The app offers coin control, fee optimization, batching and other useful tools for verifying keys and exporting backups.

### Requirements
- iOS 13
- a Bitcoin Core full-node v0.19.0.1 (at minimum) which is running on Tor with `rpcport` exposed to a Tor V3 hidden service

### Author
Peter Denton, fontainedenton@gmail.com
PGP: 3B37 97FA 0AE8 4BE5 B440  6591 8564 01D7 121C 32FC

### Built with
- [Tor.framework](https://github.com/iCepa/Tor.framework) by the [iCepa project](https://github.com/iCepa) - for communicating with your nodes hidden service
- [LibWally-Swift](https://github.com/blockchain/libwally-swift) built by @sjors - for BIP39 mnemonic creation and HD key derivation
- [Base32](https://github.com/norio-nomura/Base32/tree/master/Sources/Base32) built by @norio-nomura - for Tor V3 authentication key encoding
- [Keychain-Swift](https://github.com/evgenyneu/keychain-swift) built by @evgenyneu for securely storing sensitive data on your devices keychain

### Copyright & License

This code in this repository is Copyright © 2019 by Blockchain Commons, LLC, and is [licensed](https://github.com/BlockchainCommons/Bitcoin-Standup/tree/master/LICENSE.md) under the [spdx:BSD-2-Clause Plus Patent License](https://spdx.org/licenses/BSD-2-Clause-Patent.html).

### Contributing

We encourage public contributions through issues and pull-requests! Please review [CONTRIBUTING.md](https://github.com/BlockchainCommons/Bitcoin-Standup/tree/master/CONTRIBUTING.md) for details on our development process. All contributions to this repository require a GPG signed [Contributor License Agreement](https://github.com/BlockchainCommons/Bitcoin-Standup/tree/master/CLA.md).


