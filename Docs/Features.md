# Using FullyNoded 2

FullyNoded 2 allows you to: add a node; create a wallet; access a wallet; receive funds; spend funds; view additional information; and receover a wallet. Instructions on how to use each feature follow, as does a wishlist of potential future expansions.

For more information on how these features actually function, see ["How It Works"](How-it-works.md).

## Adding a Node

<img src="../Images/scanQuickConnect.PNG" alt="FullyNoded 2 app Home Screen" width="250"/>

When initially starting up FullyNoded 2, a user may choose to connect to their own node by scanning a [QuickConnect QR](https://github.com/BlockchainCommons/Bitcoin-Standup#quick-connect-url-using-btcstandup) or link to a testnet node that we are currently utilizing for development purposes by tapping the "don't have a node?" button.

## Creating a Wallet

Once you are connected to a node, you may go to the "Wallets" tab and create either a single-sig or multi-sig wallet:

<img src="../Images/choose_wallet_type_screen.PNG" alt="" width="250"/> <img src="../Images/wallet_label_screen.PNG" alt="" width="250"/> 

Once the wallet is successfully created on your node you will be guided through a confirmation flow. You will first need to give your wallet a label, so that you can easily recognize it. Note that this label is included in the Recovery QR, so if you use the Recovery QR to recover the wallet the label will persist! 

Please save the recovery items in order to be able to recover your wallet! If you do not do this you are at risk of permanently losing your funds. Simple tap the recovery QR to export it and save it. It should not be saved onto your device, as the whole point is that you will need it if you lose your device. We recommend printing it on waterproof paper and saving it in multiple secure locations.

<img src="../Images/wallet_recovery_QR.PNG" alt="" width="250"/> <img src="../Images/wallet_recovery_QR_export.PNG" alt="" width="250"/>

<img src="../Images/wallet_recovery_phrase_intro.PNG" alt="" width="250"/> <img src="../Images/wallet_offline_recovery_words.PNG" alt="" width="250"/>

The final screen in the wallet created confirmation flow is the offline recovery words. From that screen, you can copy the words to clipboard, export them, or display them in QR code format. It is extremely important for multi-sig wallets that the recovery words are saved; for single-sig wallets, that is redundant to the Recovery QR. It is recommended you write these down on waterproof paper and save them securely in multiple locations. For multi-sig wallets they are required for wallet recovery and refilling the keypool. 

## Accessing a Wallet

<img src="../Images/wallets_screen.PNG" alt="" width="250"/> <img src="../Images/seed_export.PNG" alt="" width="250"/> <img src="../Images/utxos.jpeg" alt="" width="250"/> 

<img src="../Images/export_keys.PNG" alt="" width="250"/> <img src="../Images/verify_addresses.PNG" alt="" width="250"/>

After creating a wallet, you will see it on the "Wallets" page. Tap it to activate it. 

* Tap the info button to display and export your device's seed info and the Recovery QR at anytime. You will always be prompted for 2FA whenever you export a seed or a private key. 
* Tap the eyeball to export all the keys associated with the wallet. These keys will be derived from the device if possible. 
* Tap the verify button to fetch the addresses purely from your node so you may "verify" that the addresses your device derives are the same as the one your node derives. For now LibWally will not derive BIP44/49 multi-sig addresses. These addresses must be fetched from your node. BIP84 multi-sig addresses will be derived locally using LibWally. 
* Tap the list button to see the wallet's UTXOs. This fetches your wallet's UTXOs from your node. From your node's perspective the UTXOs are always watch-only, as your node is never holding enough private keys to fully spend one of them. You may tap each utxo to see all the info in JSON format that your node holds for that UTXO.

## Receiving Funds

<img src="../Images/create_invoice.PNG" alt="" width="250"/>

To receive funds, activate the wallet you want to receive from and then tap the "In" tab. This will fetch a receiving address from your node for your active wallet. To fetch another one, tap the refresh button in the top right corner. The "amount" and "label" field conform to BIP21: you can add amounts and a label so the spender can simply scan the QR and it will automatically populate the amount field on their end if their software is BIP21 compatible.

## Spending Funds

<img src="../Images/pay_invoice.PNG" alt="" width="250"/> <img src="../Images/confirm_transaction.PNG" alt="" width="250"/>

To send funds, just tap the "Out" tab. From here you can tap the scanner button to scan a BIP21 compatible QR code or an address. You can also tap the + button to add multiple outputs to your transaction (batching). Whenever you are ready to build the transaction just tap "next".

## Viewing Histories, Details, and Other Information

<img src="../Images/home_screen_expanded.PNG" alt="" width="250"/> <img src="../Images/home_screen_balance_transactions.PNG" alt="" width="250"/>

You may expand the cells to show more info about your Tor connection, node statistics, and your wallet by tapping the expand/collapse buttons on the home screen.

You can see all the details associated with your wallet along with transaction history. You will see an ⚠︎ icon for any unconfirmed balances and their associated transactions. You can tap the refresh buttons to reload individual sections or pull the screen to reload all sections.

It is worth noting that the three panes in a multi-sig wallet are communicating the wallets derivation scheme and what is held by the device, node, and offline backup. Your device holds the seed so it can sign for any key, but your node holds a very specific range of keys; here we show you the current wallet index and the maximum index range. Whenever your wallet's current index reaches 100 keys from the maximum range imported into your node, you will automatically be notified and prompted to refill the keypool. It should be noted that you can refill the keypool at anytime.

## Recovering a Wallet

Please see [Recovery.md](./Docs/Recovery.md) for full details of how this works.

You may either input the offline recovery words or the Recovery QR code to recover wallets.

You may input the words one at a time or all at once; once the mnemonic is verified to be valid you will get an alert.

Similarly, upon scanning a valid Recovery QR you will also be alerted.

The "scan Recovery QR" button will also display that the QR was valid after scanning.

Depending on what you are recovering you may "Tap to Recover" once a valid QR and/or words are added.

<img src="../Images/wallet_recovery_add_words.PNG" alt="" width="250"/> <img src="../Images/wallet_recovery_valid_mnmemonic.PNG" alt="" width="250"/> <img src="../Images/wallet_recovery_valid_QR.PNG" alt="" width="250"/> <img src="../Images/confirm_recovery.PNG" alt="" width="250"/>

Upon tapping "Tap to recover" you will be presented with a "Recovery Confirmation" screen.

If you used a Recovery QR *FN2* will be able to display all of the wallet's meta data to you for confirmation. If the wallet still exists on your node, it will also be able to fetch the balance. if you are only using words *FN2* will only be able to fetch the wallet name, addresses, and derivation type.

The important part of this page is that it displays the first five addresses derived from the seed. If you you know what addresses to expectm you can verify that they match here.

Upon tapping "Confirm", the wallet will be added and the node will rescan the blockchain automatically to ensure your balances show up.

## Wishlist

- [ ] Wallet Functions
  - [x] Offline PSBT signing
  - [x] Offline raw transaction signing
  - [x] Spend and Receive
  - [x] Segwit
  - [x] Non-custodial
  - [ ] Coin Control
  - [x] BIP44
  - [x] BIP84
  - [x] BIP49
  - [x] BIP32
  - [x] BIP21
  - [x] Custom mining fee
  - [x] Multisig
  - [ ] Cold storage
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
  - [x] 2FA

- [ ] Compatible Nodes
  - [x] Your own Bitcoin Core node
  - [x] MacOS - [StandUp.app](https://github.com/BlockchainCommons/Bitcoin-StandUp-MacOS)
  - [x] Linux - [StandUp.sh](https://github.com/BlockchainCommons/Bitcoin-StandUp-Scripts)
  - [x] Nodl
  - [x] myNode
  - [x] BTCPayServer
  - [x] RaspiBlitz
  - [ ] Wasabi
  - [ ] CasaHodl

