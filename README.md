# FullyNoded 2

### Status

FullyNoded 2 is currently under active development and in the early testing phase. It should only be used on testnet for now.

FullyNoded 2 is designed to work with the [MacOS StandUp.app](https://github.com/BlockchainCommons/Bitcoin-Standup/tree/master/StandUp) and [Linux scripts](https://github.com/BlockchainCommons/Bitcoin-Standup/tree/master/LinuxScript), but will work with any properly configured Bitcoin Core 0.19.0.1 node with a hidden service controlling `rpcport` via localhost. Supporting nodes are [Nodl](https://www.nodl.it/), [BTCPayServer](https://btcpayserver.org) and [RaspiBlitz](https://github.com/rootzoll/raspiblitz), these nodes can be connected by clicking a link or scanning a qr code. Please refer to their telegram groups for simple instructions: 

- [Nodl Telegram](https://t.me/nodl_support)
- [BTCPayServer](https://t.me/btcpayserver)
- [RaspiBlitz Telegram](https://t.me/raspiblitz)

### Testflight

We have a public link available for beta testing [here at this link](https://testflight.apple.com/join/OQHyL0a8), please bare in mind the app may change drastically and may not be backward compatible, please only use the app on testnet.

### What does it do?

#### Initial Setup

Upon on initial use the user may choose to connect to their own node or a testnet node we are currently utilzing for development purposes. Once you are connected to a node you may go to the "Wallets" tab and create either a Single-Sig, Multi-Sig or Custom wallet.

##### Single-Signature

Single signature wallets take a unique approach in that a new wallet is created on your node with private keys disabled and avoid address reuse set to true. Once the wallet creation is confirmed on your node the app will utilize the LibWally-Swift libary in conjunction with Apple's native cryptographically secure random number generator to generate a seed locally. The seed is encrypted and stored on the device only. The entropy is converted into a 12 word BIP39 recovery phrase, the app then utilizes the `importmulti` rpc command to derive 2,000 public keys from the seeds BIP84 xpub. This allows your node to handle all the transaction building with the rpc command `walletcreatefundedpsbt` which handles coin selection, fee optimization and avoids address reuse. The app will create the unsinged psbt with your node and then signs the psbt locally so that your private keys are *never* broadcasted over Tor.

##### Multi-Signature

By default FullyNoded 2 will create a 2 of 3 mutlisignature wallet whereby all three seeds are created locally. One seed is converted to BIP39 words for the user to record securely for recovery purposes and then deleted forever from the device. The app will then create a wallet on your node and utilizes the `importmulti` command to import 2,000 BIP84 private keys to your nodes wallet so that it may sign for one of the two required signatures. The third seed is saved locally to your device as a BIP39 mnemonic. When it comes to spending again we utilize `walletcreatefundedpsbt` on your node to handle coin selection, and fee optimization. Yoru node will then sign the psbt and pass it to the app at which time the app will sign for the second signature locally. With this set up a user may lose either their node, device or back recovery words and still be able to spend their bitcoin's. In a future release the app will allow multiple levels of secureity including 2fa and wallet.dat encryption which would mean even if an attacker got hold of your device they would need you decryption password to spend funds.

##### Custom

At present htis feature is baing utilized for testing purposes only. The idea being we want to allow purely watch-only wallets for deep cold storage whilst also allwoing users to sign PSBT's offline, or pass unsigned PSBT's to other signers. For now this is not ready for active use but will be in the near future. If you want to test it you can make any wallet cold in the wallets view by tapping the cold button or by importing a public key descriptor from one of your exisiting wallets.

#### Wishlist

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

#### Everyday use

Currently the app is fully capable of creating and signing PSBT's with either multisig or single signature wallets. The app offers coin control, fee optimization, batching and other useful tools for verifying keys and exporting backups.

### Requirements
- iOS 13
- a Bitcoin Core full-node v0.19.0.1 (at minimum) which is running on Tor with `rpcport` exposed to a Tor V3 hidden service

### Author
Peter Denton, fontainedenton@gmail.com

### Built with
- [Tor.framework](https://github.com/iCepa/Tor.framework) by the [iCepa project](https://github.com/iCepa) - for communicating with your nodes hidden service
- [LibWally-Swift](https://github.com/blockchain/libwally-swift) built by @sjors - for BIP39 mnemonic creation and HD key derivation
- [Base32](https://github.com/norio-nomura/Base32/tree/master/Sources/Base32) built by @norio-nomura - for Tor V3 authentication key encoding
- [Keychain-Swift](https://github.com/evgenyneu/keychain-swift) built by @evgenyneu for securely storing sensitive data on your devices keychain

# Contributing

We love your input! We want to make contributing to this project as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## We Develop with Github
We use GitHub to host code, to track issues and feature requests, as well as accept Pull Requests.

## Report bugs using Github's [issues](https://github.com/briandk/transcriptase-atom/issues)
We use GitHub issues to track public bugs.

If you find bugs, mistakes, inconsistencies in this project's code or documents, please let us know by [opening a new issue](./issues), but consider searching through existing issues first to check and see if the problem has already been reported. If it has, it never hurts to add a quick "+1" or "I have this problem too". This helps prioritize the most common problems and requests.

## Write bug reports with detail, background, and sample code
[This is an example](http://stackoverflow.com/q/12488905/180626) of a good bug report by @briandk. Here's [another example from craig.hockenberry](http://www.openradar.me/11905408).

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can. [The stackoverflow bug report](http://stackoverflow.com/q/12488905/180626) includes sample code that *anyone* with a base R setup can run to reproduce what I was seeing
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

People *love* thorough bug reports. I'm not even kidding.

## Submitting code changes through Pull Requests

Simple Pull Requests to fix typos, document, or fix small bugs are always welcome.

We ask that more significant improvements to the project be first proposed before anybody starts to code as an [issue](./issues) or as a [draft Pull Request](./pulls) (GitHub has a nice new feature for simple Pull Requests called [Draft Pull Requests](https://github.blog/2019-02-14-introducing-draft-pull-requests/). This gives other contributors a chance to point you in the right direction, give feedback on the design, and maybe point out if related work is already under way.

## We Use [Github Flow](https://guides.github.com/introduction/flow/index.html), So All Code Changes Happen Through Pull Requests
Pull Requests are the best way to propose changes to the codebase (we use [Github Flow](https://guides.github.com/introduction/flow/index.html)). We actively welcome your Pull Requests:

1. Fork the repo and create your branch from `master`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that Pull Request!

## Any code contributions you make will be under the BSD-2-Clause Plus Patent License
In short, when you submit code changes, your submissions are understood will be available under the same [BSD-2-Clause Plus Patent License](./LICENSE.md) that covers the project. We also ask all code contributors to GPG sign the [CONTRIBUTOR-LICENSE-AGREEMENT.md](./CONTRIBUTOR-LICENSE-AGREEMENT.md) to protect future users of this project. Feel free to contact the maintainers if that's a concern.

## Use a Consistent Coding Style
* We indent using two spaces (soft tabs)
* We ALWAYS put spaces after list items and method parameters ([1, 2, 3], not [1,2,3]), around operators (x += 1, not x+=1), and around hash arrows.
* This is open source software. Consider the people who will read your code, and make it look nice for them. It's sort of like driving a car: Perhaps you love doing donuts when you're alone, but with passengers the goal is to make the ride as smooth as possible.

## References

Portions of this CONTRIBUTING.md document were adopted from best practices of a number of open source projects, including:
* [Facebook's Draft](https://github.com/facebook/draft-js/blob/a9316a723f9e918afde44dea68b5f9f39b7d9b00/CONTRIBUTING.md)
* [IPFS Contributing](https://github.com/ipfs/community/blob/master/CONTRIBUTING.md)

## License

BSD-2-Clause Plus Patent License

SPDX-License-Identifier: [BSD-2-Clause-Patent](https://spdx.org/licenses/BSD-2-Clause-Patent.html)

Copyright © 2019 Blockchain Commons, LLC

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Subject to the terms and conditions of this license, each copyright holder and contributor hereby grants to those receiving rights under this license a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable (except for failure to satisfy the conditions of this license) patent license to make, have made, use, offer to sell, sell, import, and otherwise transfer this software, where such license applies only to those patent claims, already acquired or hereafter acquired, licensable by such copyright holder or contributor that are necessarily infringed by:

(a) their Contribution(s) (the licensed copyrights of copyright holders and non-copyrightable additions of contributors, in source or binary form) alone; or
(b) combination of their Contribution(s) with the work of authorship to which such Contribution(s) was added by such copyright holder or contributor, if, at the time the Contribution is added, such addition causes such combination to be necessarily infringed. The patent license shall not apply to any other combinations which include the Contribution.
Except as expressly stated above, no rights or licenses from any copyright holder or contributor is granted under this license, whether expressly, by implication, estoppel or otherwise.

DISCLAIMER

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


