# Installing GordianWallet from Source

You can build the *GordianWallet* by installing a number of tools on your local Macintosh.

## 1. Install Xcode

Install Apple's Xcode developer environment, and download the Gordian Wallet source.

- [Install Xcode](https://itunes.apple.com/id/app/xcode/id497799835?mt=12)
- You will need a free Apple developer account: create one [here](https://developer.apple.com/programs/enroll/)
- In Xcode, click "Xcode" > "preferences" > "Accounts" and add your github account

## 2. Install Xcode command line tools
`xcode-select --install`

## 3. Install Brew

Run `brew --version` in a terminal, if you get a valid response you have brew installed already, if not:
- `cd /usr/local`
- `mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew`
- Wait for brew to finish

## 4. Install Dependencies
- `brew install carthage automake autoconf libtool gnu-sed`

## 5. Install GordianWallet
- `git clone https://github.com/BlockchainCommons/GordianWallet-iOS.git --recurse-submodules`
- `cd Gordian-Wallet-iOS/XCode`
- `carthage build --platform iOS`

## 6. Open GordianWallet
- open `GordianWallet.xcodeproj` and run the project in a simulator or device.

## 7. Troubleshooting
Carthage should build everything automatically, if for some reason it does not you may need to manually compile libwally-core:
- `cd Gordian-Wallet-iOS/XCode/Carthage/Checkouts/libwally-swift`
- `./build-libwally.sh -dsc`



