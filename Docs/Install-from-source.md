# Installing FullyNoded 2 from Source

You can build the FullyNoded 2 iOS mobile wallet by installing a number of tools on your local Macintosh.

## 1. Install XCode

Install Apple's XCode developer environment, and download the FullyNoded 2 source.

- [Install Xcode](https://itunes.apple.com/id/app/xcode/id497799835?mt=12)
- You will need a free Apple developer account: create one [here](https://developer.apple.com/programs/enroll/)
- In Xcode, click "Xcode" > "preferences" > "Accounts" and add your github account

## 2. Install Brew

Run `brew --version` in a terminal, if you get a valid response you have brew installed already, if not:
- `cd /usr/local`
- `mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew`
Wait for brew to finish.

## 3. Install Carthage
- `brew install carthage`

## 3. Clone FullyNoded-2
- `git clone https://github.com/BlockchainCommons/FullyNoded-2.git`

## 4. Build Dependencies
- `cd FullyNoded-2/XCode`
- `carthage update --platform iOS`

## 5. Edit LibWally.xcodeproj
**This is a temporary fix while we wait for the next LibWally update.**
- `cd FullyNoded-2/XCode/Carthage/Checkouts/libwally-swift`
- open `LibWally.xcodeproj`
- Navigate to `LibWally/BIP32.swift` and edit line #253 from `var privKey` to `public var privKey`
- Navigate to  `LibWally/PSBT.swift` and edit line #14 from `let path: BIP32Path` to `public let path: BIP32Path`
- Save and close Libwally.xcodeproj
- **Turn off your internet connection to force LibWally to build from source**
- `cd FullyNoded-2/XCode`
- `carthage build libwally-swift`

## 6. Open FullyNoded-2
- `cd FullyNoded-2/XCode`
- open `FullyNoded2.xcodeproj` and run the project in a simulator or device.


