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

- 1. User loses their node or somehow deletes the wallet from their node.

        - The user will need to connect to a node, then scan the Recovery QR and input their 12 word offline recovery phrase and tap "Recover now".

- 2. User loses their device.

        - The user connects to their node and scans the Recovery QR to restore the wallet on their device.

- 3. User loses both device and node.

        - The user will need to connect to a node, then scan the Recovery QR and input their 12 word offline recovery phrase and tap "Recover now".

### Single-Signature Wallets

- 1. User loses their node.

        - The user will connect a new node and then scan or upload a Recovery QR at which point the node will automatically rescan for balances.

- 2. User loses their device.

        - User downloads the app on another device, connects their node and scans or uploads the Recovery QR.
        
In either scenario a user may recover a single-sig wallet with just their recovery words, the app will prompt you to choose a derivation path and will automatically rescan the blockchain to show balances.
            

## Recovery QR

The Recovery QR is to be accesible to the user at anytime by tapping the info button next to the devices seed cell on the Wallets view controller, the user will be prompted to "Sign in with Apple" at this point for 2FA (two-factor authentication) purposes before any of the seed info will be accessed.

A Recovery QR is a simple json dictionary which consists of four mandatory values: `entropy`, `descriptor`,  `birthdate` and `blockheight`.

- Single-Signature RecoveryQR example:

```
{

    entropy:"ed3032b2f69ad7037d0a1ab388d91065", descriptor:"wpkh([fb41f110/84'/1'/0']tprv8fS7KWqL7UPBPtb8Q5dPKf7BtSyVYb1pGAs23znVpETNkAbEQvx59JNLWhWHBZRuJfkFszUwEjk1rDS6dUz2SFXxGMDMytw1TqSfA5tDBDD/0/*)#fjskw8",
    birthdate:1582800776,
    blockheight:61904
    label:"FullyNoded2 - SingleSig"
    
}
```

- Multi-Signature RecoveryQR example:

```
{
   
   entropy:"ed3032b2f69ad7037d0a1ab388d91065", descriptor:"wsh(multi(2,[cc2b88d9/84'/1'/0']tpubDDhKDzr8EeYqLP27xchAptrpUEqWecPGEXnjq3d1pKjzbHd6r7DKRPtBMxtQtjoCCqckVBoX6cfiGkBiJffGJYV3dMtabCp9bro29riQtKL/0/*,[ff7a130e/84'/1'/0']tprv8gEZHzJzKfefuNEzWstVsdzmE86SiMK8i8cZUMNDNVTcEWGZJknhKGYNJvRBoXG3R83BGPnrEWrCH2ogKEFUyUZXP8BgL1taExx2P884qUT/0/*,[8f7dba7b/84'/1'/0']tpubDDauNnbmWAmFaxbUDeYsHfsqgF5EK33eLpbw7W5eJz4V3sJ53tnTD2BjYEzJAX7DDscbZMg877vi9o5dyunG52FNDCqjnu126wKHxujMmzp/0/*))#ifjf8",
   birthdate:1582800776,
   blockheight:61904,
   label:"FullyNoded2 - MultiSig"
   
}
```

- `entropy` (string - required)

The hexadecimal string representation of the binary entropy used to derive your BIP39 mnemonic. We include this in the RecoveryQR so that we do not lose the 12 word mnemonic phrase when recovering wallets. The devices seed may be derived from this entropy. The multi-sig RecoveryQR will never be capable of signing for more then 1 of the 2 required signatures.

- `descriptor` (string -required)

Represents the wallets xprv, derivation path, address format and also the extended public keys associated with a multi-sig wallet. For more info about descriptors see this [link](https://github.com/bitcoin/bitcoin/blob/master/doc/descriptors.md). FullyNoded 2 utilizes descriptors frequently throughout the app, therefore it is efficient programmatically to simply include them in the Recovery QR rather then seperate fields for derivation paths, address format, multi-sig public keys etc. The provided checksum is always the checksum for the public key descriptor, during the wallet recovery process we manipulate the descriptor by converting it back to a public key descriptor and save it for fetching addresses. We save the public key checksum as it is more efficient programmatically and results in less bitcoin-cli commands. The order of the extended keys is significant. The first key represents the offline recovery seed, the second key represents the device's seed and the third key represents the node's seed.

- `birthdate` (integer - required)

Represents the unix timestamp for the birthdate of the seed associated with the wallet. We include this value in the `bitcoin-cli` recovery options under the Seed Info view, that way if the user does recover on their own node the wallet will automatically rescan to show historical transactions/balances.

- `blockheight` (integer - required)

Represents the blockheight when the wallet was first created, this is used to rescan the blockchain after the wallet is successfully recovered. Because we use multiple `importmulti` commands when creating/recovering wallets we can not use the `birthdate` to rescan for each `importmulti` command.

- `label` (string - optional)

The label a user may add to a wallet to easily identify it. This feature will soon be added to FullyNoded 2 and is therefore included here for forward compatibility.

  CAVEATS:

    - We are only including the primary descriptor in the RecoveryQR Code, FullyNoded 2 is smart enough to parse the descriptor then create and import the change descriptor into the node during the recovery process.

