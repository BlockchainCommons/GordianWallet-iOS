# Installing FullyNoded 2 from Source

You can build the FullyNoded 2 iOS mobile wallet by installing a number of tools on your local Macintosh.

## 1. Install XCode

Install Apple's XCode developer environment, and download the FullyNoded 2 source.

- [Install Xcode](https://itunes.apple.com/id/app/xcode/id497799835?mt=12)
- You will need a free Apple developer account: create one [here](https://developer.apple.com/programs/enroll/)
- In XCode, click "XCode" -> "preferences" -> "Accounts" and add your github account
- Go to the [repo](https://github.com/BlockchainCommons/FullyNoded-2) for FullyNoded 2 and click `Clone and Download` -> `Open in XCode`
- Once it opens, go ahead and close it for now and quit XCode

## 2. Install Brew

Run `brew --version` in a terminal, if you get a valid response you have brew installed already, if not:

```
cd /usr/local
mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
```
Wait for brew to finish.

## 3. Install carthage

`brew install carthage`

## 4. Install dependencies via carthage

```
cd FullyNoded-2/XCode
carthage update --platform iOS
```

## 5. Run it!

Open and run `FullyNoded-2/XCode/FullyNoded2.xcodeproj`
