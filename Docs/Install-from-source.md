# Installing Gordian Wallet from Source

You can build the Gordian Wallet by installing a number of tools on your local Macintosh.

## 1. Install XCode

Install Apple's XCode developer environment, and download the Gordian Wallet source.

- [Install Xcode](https://itunes.apple.com/id/app/xcode/id497799835?mt=12)
- You will need a free Apple developer account: create one [here](https://developer.apple.com/programs/enroll/)
- In Xcode, click "Xcode" > "preferences" > "Accounts" and add your github account

## 2. Install Brew

Run `brew --version` in a terminal, if you get a valid response you have brew installed already, if not:
- `cd /usr/local`
- `mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew`
- Wait for brew to finish

## 3. Install Dependencies
- `brew install carthage automake autoconf libtool gnu-sed`

## 3. Clone Gordian-Wallet
- `git clone https://github.com/BlockchainCommons/Gordian-Wallet.git`

## 4. Build Dependencies
- `cd Gordian-Wallet/XCode`
- `carthage bootstrap --platform iOS`

## 5. Open Gordian-Wallet
- `cd Gordian-Wallet/XCode`
- open `GordianWallet.xcodeproj` and run the project in a simulator or device.



