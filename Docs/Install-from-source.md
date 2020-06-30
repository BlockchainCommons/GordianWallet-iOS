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

## 3. Get dependencies for Libwally
- `brew install autoconf automake libtool gnu-sed`

## 4. Clone FullyNoded-2
- `git clone https://github.com/BlockchainCommons/FullyNoded-2.git`

## 5. Build Libwally
- `cd FullyNoded-2/XCode/Carthage/Checkouts/libwally-swift`
- `./build-libwally.sh -dsc`

## 6. Run FullyNoded-2
- `cd FullyNoded-2/XCode`
- open `FullyNoded2.xcodeproj`


