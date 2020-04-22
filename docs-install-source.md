# Installing FullyNoded 2 from Source

You can build the FullyNoded 2 iOS mobile wallet by installing a number of tools on your local Macintosh.

## Install Brew

Run `brew --version` in a terminal, if you get a valid response you have brew installed already, if not:

```
cd /usr/local
mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
```
Wait for brew to finish.

## Install carthage

Follow these [instructions](https://brewinstall.org/install-carthage-on-mac-with-brew/) to install to Cocoa dependency manager using brew.

##### Install XCode

Install Apple's XCode developer environment, and download the FullyNoded 2 source.

- [Install Xcode](https://itunes.apple.com/id/app/xcode/id497799835?mt=12)
- You will need a free Apple developer account: create one [here](https://developer.apple.com/programs/enroll/)
- In XCode, click "XCode" -> "preferences" -> "Accounts" and add your github account
- Go to the [repo](https://github.com/BlockchainCommons/FullyNoded-2) for FullyNoded 2 and click `Clone and Download` -> `Open in XCode`
- Once it opens, go ahead and close it for now and quit XCode

##### Install Tor.Framework Dependencies

These steps will ensure Tor.framework builds successfully, it will create a completely separate Tor.framework directory on your machine which should not be confused with *FN2* or its Tor.framework.

```
brew install automake
brew install autoconf
brew install libtool
brew install gettext
git clone git@github.com:iCepa/Tor.framework
cd Tor.framework
git submodule init
git submodule update
carthage build --no-skip-current --platform iOS
```
It is normal to see an error about xcconfigs in the above process. It can be ignored.

Once the above process completes you can:
```
cd <into FullyNoded2>
carthage update --platform iOS
```

##### Install LibWally-Swift with Cocoapods

Finally, install the Swift cryptocurrency primitives.

- First run `brew install gnu-sed` as it is required to build LibWally-Swift
- If you don't have Cocoapods, install it with `sudo gem install cocoapods`
- `cd <into the project>` (FullyNoded 2)
- run `pod install`

You are now ready to compile FullyNoded 2 in Xcode!

- Upon first running FullyNoded 2 you will most likely need to make a few variables `public` in LibWally-Swift. This is because the way the app works requires us to get access to private keys to sign transactions with and psbt input paths in order to fetch private keys for signing. You will see a `X not accessible due to internal protection` error: simply go to that variable make it public then run the project again in XCode.
