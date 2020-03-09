# Recovery

## Status

Currently the recovery capability is being worked on. At present users may fully recover any wallet in the event they lose their *device*. Recovery for user's who have lost their node is still a WIP.

To recover a wallet either tap the QR button on the top left of the home screen and scan a RecoveryQR or go to "Wallets" -> "+" -> "Recover Wallet" -> "Scan a RecoveryQR"

## Overview

When creating a multi-signature wallet the user will be presented with a *Recovery Kit*. It comprises a 12 word BIP39 mnemonic which represents the offline seed and third signer for the 2 of 3 multi-signature wallet. 

The user may at any time export and save the RecoveryQR code for any type of wallet, however once the user taps the "I saved them" button during the mulit-signature wallet creation flow the 12 word BIP39 mnemonic will be gone forever and is in no way shape or form stored on the users device or node.

For all wallet types the user may at anytime go to the "Seed Info" view controller and see all the relevant informaion for their device's seed; including the RecoveryQR, 12 word BIP39 mnemonic, private key descriptors and even a verbose command for recreating the wallet on their own node via `bitcoin-cli`.

## Scenarios to consider

### Multi-Signature Wallets

- 1. User loses their node (WIP).

        - The user will need to connect a new node and recover the wallet with their Recovery Kit 12 words. The device still holds all the info needed to recreate the wallet for a single signer. This would best be achieved in the UI with a "sweep to" or "roll over" function where the wallet can be transferred to a new node. The user will be prompted to add a signer to the wallet in the form of the 12 word Recovery Kit mnemonic. The app will automatically rescan up to the wallets birthdate.

- 2. User loses their device.

        - The user will need their RecoveryQR. They can simply scan or upload the RecoveryQR and the app will find the wallet on the node, connect to it and then encrypt and save the local xprv to the device so that it may be the second signer for the wallet.

- 3. User loses both device and node.

        - The user will need both the Recovery Kit words and the RecoveryQR. The user may import the 12 words by manually typing them in on the RecoveryViewController, once the words are added they can scan or upload a RecoveryQR at which point the wallet will be completely recreated on the node and device. At this point the node will automatically rescan for any exisiting balances.

### Single-Signature Wallets

- 1. User loses their node (WIP).

        - The user will connect a new node and then scan or upload a RecoveryQR at which point the node will automatically rescan for balances.

- 2. User loses their device.

        - User downloads the app on another device, connects their node and scans or uploads the RecoveryQR. Once the wallet is recovered the user will need to manually either tap the refresh button on the wallet or activate the wallet by toggling it on and navigating to the home screen for the balance to refresh.
            
### Both Wallet Types

- 1. User only backs up the 12 words and nothing else (WIP).

        - Allow user to import only the words, then we can simply import each wallet derivation into the node and start a rescan, displaying to the user the rescan status in the UI. We as mentioned above will alos be adding the ability to add a signer to wallets, so that a user may make a watch-only wallet hot or add additional signers to a mutli-signature wallet. This aproach will provide a lot of flexibility.
            
It is worth noting the app also allows a user to import any type of descriptor, this functionality is quite basic at the moment as it does not allow for key management of any sort, it will simply import into the node whatever is supplied by the user, no keys will be stored locally as the app stands.

## RecoveryQR

The RecoveryQR is to be accesible to the user at anytime by tapping the info button next to the devices seed cell on the Wallets view controller, the user will be prompted to "Sign in with Apple" at this point for 2FA (two-factor authentication) purposes before any of the seed info will be accessed.

A RecoveryQR is a simple json dictionary which consists of five mandatory values: `entropy`, `descriptor`, `walletName`,  `birthdate` and `blockheight`.

- Single-Signature RecoveryQR example:

```
{

    entropy:"ed3032b2f69ad7037d0a1ab388d91065", 
    descriptor:"wpkh([fb41f110/84'/1'/0']tprv8fS7KWqL7UPBPtb8Q5dPKf7BtSyVYb1pGAs23znVpETNkAbEQvx59JNLWhWHBZRuJfkFszUwEjk1rDS6dUz2SFXxGMDMytw1TqSfA5tDBDD/0/*)",
    walletName:"DEFAULT_nue8339_StandUp",
    birthdate:1582800776,
    blockheight:61904
    label:"FullyNoded2 - SingleSig"
    
}
```

- Multi-Signature RecoveryQR example:

```
{
   
   entropy:"ed3032b2f69ad7037d0a1ab388d91065", descriptor:"wsh(multi(2,[cc2b88d9/84'/1'/0']tpubDDhKDzr8EeYqLP27xchAptrpUEqWecPGEXnjq3d1pKjzbHd6r7DKRPtBMxtQtjoCCqckVBoX6cfiGkBiJffGJYV3dMtabCp9bro29riQtKL/0/*,[ff7a130e/84'/1'/0']tprv8gEZHzJzKfefuNEzWstVsdzmE86SiMK8i8cZUMNDNVTcEWGZJknhKGYNJvRBoXG3R83BGPnrEWrCH2ogKEFUyUZXP8BgL1taExx2P884qUT/0/*,[8f7dba7b/84'/1'/0']tpubDDauNnbmWAmFaxbUDeYsHfsqgF5EK33eLpbw7W5eJz4V3sJ53tnTD2BjYEzJAX7DDscbZMg877vi9o5dyunG52FNDCqjnu126wKHxujMmzp/0/*))",
   walletName:"MULTI_nue8339_StandUp",
   birthdate:1582800776,
   blockheight:61904,
   label:"FullyNoded2 - MultiSig"
   
}
```

- `entropy` (string - required)

The hexadecimal string representation of the binary entropy used to derive your BIP39 mnemonic. We include this in the RecoveryQR so that we do not lose the 12 word mnemonic phrase when recovering wallets. The devices seed may be derived from this entropy. The multi-sig RecoveryQR will never be capable of signing for more then 1 of the 2 required signatures.

- `descriptor` (string -required)

Represents the wallets xprv, derivation path, address format and also the extended public keys associated with a multi-sig wallet. For more info about descriptors see this [link](https://github.com/bitcoin/bitcoin/blob/master/doc/descriptors.md). FullyNoded 2 utilizes descriptors frequently throughout the app, therefore it is efficient programmatically to simply include them in the Recovery QR rather then seperate fields for derivation paths, address format, multi-sig public keys etc.

- `walletName` (string - required)

Represents the wallet.dat files name on the users node. This will be useful in scenarios where a user loses their device but not their node as we can programmatically verify it still exists on the node and connect to it. No rescanning of the blockchain will be necessary when recovering wallets in this manner.

- `birthdate` (integer - required)

Represents the unix timestamp for the birthdate of the seed associated with the wallet. We include this value in the `bitcoin-cli` recovery options under the Seed Info view, that way if the user does recover on their own node the wallet will automatically rescan to show historical transactions/balances.

- `blockheight` (integer - required)

Represents the blockheight when the wallet was first created, this is used to rescan the blockchain after the wallet is successfully recovered. Because we use multiple `importmulti` commands when creating/recovering wallets we can not use the `birthdate` to rescan for each `importmulti` command.

- `label` (string - optional)

The label a user may add to a wallet to easily identify it. This feature will soon be added to FullyNoded 2 and is therefore included here for forward compatibility.

### Progress

- [ ] Recovery Scenarios
    - [x] User loses their device and scans a RecoveryQR to recover a single-signature or multi-signature wallet.
    - [x] User loses both their device and node - full multi-signature recovery.
    - [ ] User loses both their device and node - full single-signature recovery.
    - [ ] Add a signer functionality.
    - [ ] Recover any BIP39 mnemonic.
    - [x] Import any descriptor.

  CAVEATS:

    - We are only including the primary descriptor in the RecoveryQR Code, FullyNoded 2 is smart enough to parse the descriptor then create and import the change descriptor into the node during the recovery process.

