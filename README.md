# FullyNoded 2

FullyNoded 2 is an open source iOS Bitcoin wallet that connects via Tor V3 authenticated service to your own Bitcoin full node bitcoind installed using either Bitcoin Standup [MacOS](https://github.com/BlockchainCommons/Bitcoin-StandUp-MacOS), [Linux Scripts](https://github.com/BlockchainCommons/Bitcoin-StandUp-Scripts) or to a number of full node boxes like [Nodl](https://www.nodl.it/), [Rasbiblitz](https://github.com/rootzoll/raspiblitz), or for use with fullnode services like [BTCpay](https://btcpayserver.org/]).

FullyNoded 2 allows for multiple wallet templates including legacy, segwit compatible, and segwit native hot wallets using a single signature (seed on iOS device), or a warm wallet using multisig (seed on iOS device, keys on full node, offline seed, etc.), as well  leverage PSBTs (Partially Signed Bitcoin Transactions) for  a number of cold wallet templates such as cold offline seeds, third-party collaborative custody services, and various air-gapped hardware solutions using QR codes. FullyNoded 2 can support potentially almost anything that can be described by a [bitcoind descriptor](https://github.com/bitcoin/bitcoin/blob/master/doc/descriptors.md).

<img src="./Images/home_screen_collapsed.PNG" alt="FullyNoded 2 app Home Screen" width="250"/> <img src="./Images/home_screen_expanded.PNG" alt="FullyNoded 2 app Home Screen" width="250"/>

## Status — Late Alpha

*FullyNoded 2* is currently under active development and in late alpha testing phase. It should only be used on Bitcoin testnet for now.

*FullyNoded 2* is designed to work with the [MacOS StandUp.app](https://github.com/BlockchainCommons/Bitcoin-StandUp-MacOS) or one of a number of [Linux scripts](https://github.com/BlockchainCommons/Bitcoin-StandUp-Scripts), but will work with any properly configured Bitcoin Core 0.19.0.1 node with a hidden service controlling `rpcport` via localhost. Supporting nodes are [Nodl](https://www.nodl.it/), [RaspiBlitz](https://github.com/rootzoll/raspiblitz), or full nodes installed by other services such as [BTCPayServer](https://btcpayserver.org). These full nodes can be connected by clicking a link or scanning a QR code. Please refer to their telegram groups for simple instructions:

- [Nodl Telegram](https://t.me/nodl_support)
- [RaspiBlitz Telegram](https://t.me/raspiblitz)
- [BTCPayServer](https://t.me/btcpayserver)

## Testflight

We have a public link available for beta testing [here](https://testflight.apple.com/join/OQHyL0a8), please only use the app on testnet. Please do share crash reports and give feedback. Want a feature added? Tell us about it.

## Financial Support

Please consider becoming a sponsor by supporting the project via GitHub's sponsorship program where they will match up to $5,000 USD in donations, more info [here](https://github.com/sponsors/BlockchainCommons). See our [Sponsors](./Sponsors.md) page for more info.

*FullyNoded 2* is a project of [Blockchain Commons, LLC](https://www.blockchaincommons.com/) a “not-for-profit” benefit corporation founded with the goal of supporting blockchain infrastructure and the broader security industry through cryptographic research, cryptographic & privacy protocol implementations, architecture & code reviews, industry standards, and documentation.

To financially support further development of *FullyNoded 2*, please consider becoming Patron of Blockchain Commons by contributing Bitcoin at our [BTCPay Server](https://btcpay.blockchaincommons.com/) or through ongoing fiat patronage by becoming a [Github Sponsor](https://github.com/sponsors/BlockchainCommons), currently GitHub will match sponsorships so please do consider this option.

### General Use

#### Adding a node

<img src="./Images/scanQuickConnect.PNG" alt="FullyNoded 2 app Home Screen" width="250"/>

Upon on initial use the user may choose to connect to their own node by scanning a [QuickConnect QR](https://github.com/BlockchainCommons/Bitcoin-Standup#quick-connect-url-using-btcstandup) or a testnet node we are currently utilizing for development purposes by tapping the "don't have a node?" button.

#### Creating a wallet

Once you are connected to a node you may go to the "Wallets" tab and create either a single-sig or multi-sig wallet:

<img src="./Images/choose_wallet_type_screen.PNG" alt="" width="250"/> <img src="./Images/wallet_label_screen.PNG" alt="" width="250"/> 

Once the wallet the wallet is successfully created on your node you will be guided through a confirmation flow. You will first need to give your wallet a label so that you can easily recognize it. It should be noted that this label is accounted for in the Recovery QR so if you use the Recovery QR to recover the wallet the label will persist. We urge the user that they must save the recovery items in order to be able to recover a wallet! If you do not do this you are at risk of permanently losing your funds. The recovery QR can be tapped to export it and save it. It should not be saved onto your device as the whole point is that you will need it if you lose your device. We recommend printing it on waterproof paper and saving it in multiple secure locations.

<img src="./Images/wallet_recovery_QR.PNG" alt="" width="250"/> <img src="./Images/wallet_recovery_QR_export.PNG" alt="" width="250"/>

<img src="./Images/wallet_recovery_phrase_intro.PNG" alt="" width="250"/> <img src="./Images/wallet_offline_recovery_words.PNG" alt="" width="250"/>

It is extremely important for multi-sig wallets that the recovery words are saved, for single-sig it is redundant to the Recovery QR. The final screen in the wallet created confirmation flow is the offline recovery words. From here you can copy them to clipboard, export them or display them in QR code format. It is recommended you write these down on waterproof paper and save them securely in multiple locations. For multi-sig wallets they are required for wallet recovery and refilling the keypool.

#### Wallets

<img src="./Images/wallets_screen.PNG" alt="" width="250"/> <img src="./Images/seed_export.PNG" alt="" width="250"/> <img src="./Images/utxos.jpeg" alt="" width="250"/> 

<img src="./Images/export_keys" alt="" width="250"/> <img src="./Images/verify_addresses" alt="" width="250"/>

After creating a wallet you will see it on the "Wallets" page. Tap it to activate it. Tap the info button to display and export your device's seed info and the Recovery QR at anytime, you will always be prompted for 2FA whenever you export a seed or a private key. Tap the eyeball to export all the keys associated with the wallet, these keys will be derived from the device if possible. For now LibWally will not derive BIP44 and 49 multi-sig addresses or scripts. These addresses must be fetched from your node. BIP84 multi-sig addresses and scripts will be derived locally using LibWally. Tap the verify button to fetch the addresses purely from your node so you may "verify" that the addresses your device derives are the same as the one your node derives. Tap the list button to see the wallet's utxo's. This fetches your wallet's utxo's from your node. From your node's perspective the utxo's are always watch-only as your node is never holding enough private keys to fully spend one of them. You may tap each utxo to see all the info in json format that your node holds for that utxo.

##### Receiving

<img src="./Images/create_invoice.PNG" alt="" width="250"/>

Just activate the wallet you want to spend from and then tap the "In" tab, it will fetch a receiving address from your node for your active wallet, to fetch another one tap the refresh button in the top right corner. The "amount" and "label" field conform to BIP21, you can add amounts and a label so the spender can simply scan the QR and it will automatically populate the amount field on their end if their software is BIP21 compatible.

##### Spending

<img src="./Images/pay_invoice.PNG" alt="" width="250"/> <img src="./Images/confirm_transaction.PNG" alt="" width="250"/>

To send just tap the "Out" tab. From here you can tap the scanner button to scan a BIP21 compatible QR code or an address. You can also tap the + button to add multiple outputs to your transaction (batching), whenever you are ready to build the transaction just tap "next".


#### Home screen

<img src="./Images/home_screen_expanded.PNG" alt="" width="250"/> <img src="./Images/home_screen_balance_transactions.PNG" alt="" width="250"/>

You may expand the cells to show more info about your Tor connection, node statistics and wallet by tapping the expand/collapse buttons.

You can see all the details associated with your wallet along with transaction history. You will see an ⚠︎ icon for any unconfirmed balances and their associated transactions. You can tap the refresh buttons to reload individual sections or pull the screen to reload all sections.

It is worth noting that the three panes in a multi-sig wallet are communicating the wallets derivation scheme and what is held by the device, node and offline backup. Your device holds the seed so it can sign for any key, your node however holds a very specific range of keys, here we show you the current wallet index and the maximum index range. Whenever your wallet's current index reaches 100 keys from the maximum range imported into your node you will automatically be notified and prompted to refill the keypool. It should be noted you can refill the keypool at anytime.

#### Wallet recovery

Please see [Recovery.md](./Recovery.md) for full details of how it works.

You may either input the offline recovery words and/or the Recovery QR code to recover wallets.

You may input the words one at a time or all at once, once the mnemonic is verified to be valid you will get an alert.

Similarly upon scanning a valid Recovery QR you will also be alerted.

The "scan Recovery QR" button will also display that the QR was valid after scanning.

Depending on what you are recovering you may either tap "Recover now" once a valid QR and/or words are added.

<img src="./Images/wallet_recovery_add_words.PNG" alt="" width="250"/> <img src="./Images/wallet_recovery_valid_mnmemonic.PNG" alt="" width="250"/> <img src="./Images/wallet_recovery_valid_QR.PNG" alt="" width="250"/> <img src="./Images/confirm_recovery.PNG" alt="" width="250"/>

Upon tapping "Tap to recover" you will be presented with a "Recovery Confirmation" screen.

If you used a Recovery QR *FN2* will be able to display all the wallets met data to you for confirmation. If the wallet still exists on your node it will also be able to fetch the balance. if you are only using words we will only be able to fetch the wallet name, addresses and derivation type.

The important part of this page is that it displays the first five addresses derived from the seed. If you you know what addresses to expect you can verify that they match here.

Upon tapping confirm the wallet will be added and the node will rescan the blockchain automatically to ensure your balances show up.

### How does it work?

*FullyNoded 2* operates in tandem with your node, for every wallet you create with *FN2* a corresponding wallet.dat file will be created on your node using the `bitcoin-cli createwallet` command. Wallets will not be saved locally to your device until it is 100% confirmed that the wallet and its keys were successfully imported into your node.

#### Wallet creation

*FN2* is currently capable of creating two core wallet types. Single-sig and a 2 of 3 multi-sig.

*FN2* will create a wallet with the following commands:

##### Single-sig wallets

`bitcoin-cli createwallet <your wallets name>, true, true, "", true`

##### Multi-sig wallets

`bitcoin-cli createwallet <your wallets name>, false, true, "", true`

From the Bitcoin Core v0.19.1 help for `createwallet`:

```
Arguments:
1. wallet_name             (string, required) The name for the new wallet. If this is a path, the wallet will be created at the path location.
2. disable_private_keys    (boolean, optional, default=false) Disable the possibility of private keys (only watchonlys are possible in this mode).
3. blank                   (boolean, optional, default=false) Create a blank wallet. A blank wallet has no keys or HD seed. One can be set using sethdseed.
4. passphrase              (string) Encrypt the wallet with this passphrase.
5. avoid_reuse             (boolean, optional, default=false) Keep track of coin reuse, and treat dirty and clean coins differently with privacy considerations in mind.
```

- 1. `<your wallets name>`: a SHA256 hash of your wallets public key descriptor. You can think of your public key descriptor as a unique fingerprint for your wallet, no two will ever be the same. This means we can name wallets deterministically based on the descriptor which holds all the information necessary to derive your wallets addresses. When you go to recover a wallet *FN2* will first create your descriptor and get its hash to see if the wallet already exists on your node or not.

- 2. `true` or `false`: the first boolean lets our node know that we want to create the wallet with `disable_private_keys` set to true for single-sig wallets and `false` for multi-sig wallets. In the single-sig wallet your node never holds any private keys at all. For multi-sig wallets it is a signer and holds 5,000 private keys derived from your nodes designated seed.

- 3. `true`: the second boolean lets our node know that we want the wallet to be created with a blank keypool so that *FN2* is 100% in control over which keys the node's wallet "knows about".

- 4. `""`: the fourth argument as an empty string tells the node that we do not want to encrypt the wallet with a passphrase. This can be done at a later time by the user if desired. If you do encrypt your wallet you will need to decrypt it before *FN2* will be able to function normally.

- 5. `true`: the fifth and final boolean argument is lets your node know that we want to avoid reusing any addresses as it is a best practice. *FN2* is smart enough to do this on its own but as your wallet also "exists" on your node you do always have the option of using this wallet without *FN2* at all. Which is why we take extra precautions to avoid any risk of address reuse.

#### Key creation

Before we ever create the wallet on your node *FN2* will first create the seeds locally on the device using your devices cryptographically secure random number generator.

For single-sig wallets a single seed is created, encrypted and stored locally.

For multi-sig wallets three seeds are initially created.

- 1. The first seed is designated as your offline recovery phrase and converted into a 12 word BIP39 mnemonic which you are responsible for storing offline. This mnemonic *must* be saved and used in order to refill your node's wallet's keypool and to recover the wallet if you lose your node or delete the wallet from the node somehow. Once you go through the wallet created confirmation flow the offline seed will be deleted from the device forever, it is never stored on the device's database, it is displayed temporarily to give you a chance to save it, then deleted forever.

- 2. The second seed is designated as your device's seed and is securely encrypted and stored locally. This seed may be exported at any time along with the Recovery QR code which itself holds this seed.

- 3. The third seed is designated for the node. It is converted to an `xprv` then the seed itself is deleted forever. It is never stored to the devices database.

At this stage the device is fully capable of signing transactions for the wallet. In order for the node to be able to sign transactions or create PSBT's we need to import keys into it.

#### Key importing

##### Multi-sig wallets

For multi-sig wallets the device converts seed #1 and #2 to xpub's and seed #3 to an xprv. *FN2* then constructs a descriptor which for a BIP84 wallet would look like this:

```
"wsh(multi(2,[10c791f9/84'/1'/0']tpubDCDH16GTAZQojSwiTbDsjJLf5GqCHacQQvG4A1rgJiH5bVwkyhcALaZbFdAoYzJDuL5p1z4uJw47W57oAMjG7M1FMLzeVvoESXQhcK3iV9a/0/*,[183d7575/84'/1'/0']tpubDCT7BpTfsrYKwtcErnu32pMdsphzCdXJkdECmgnKQeYWvfci2bKN1TGgqGqLCY2ciT4VcRymqvZJnLrCyiqZryzYhcT5RCZTt5kPEEZv3vu/0/*,[f7fa2687/84'/1'/0']tprv8ftRxc6xTpRsmi2MVzFhF5NiJiG8vPWGLZyaMZ4Y86VyPSHKYv2PySV9fTg4obY3Gchx7211p5eg7kMrG7ct6gxWYEUUvvxyisHKCZ9vhnX/0/*))"
```
`wsh` represents the address format, in this case "witness script hash".
`multi` represents a multi-sig type descriptor.
`2` represents the number of signatures required to spend from this wallet.
```
[10c791f9/84'/1'/0']tpubDCDH16GTAZQojSwiTbDsjJLf5GqCHacQQvG4A1rgJiH5bVwkyhcALaZbFdAoYzJDuL5p1z4uJw47W57oAMjG7M1FMLzeVvoESXQhcK3iV9a/0/*,[183d7575/84'/1'/0']tpubDCT7BpTfsrYKwtcErnu32pMdsphzCdXJkdECmgnKQeYWvfci2bKN1TGgqGqLCY2ciT4VcRymqvZJnLrCyiqZryzYhcT5RCZTt5kPEEZv3vu/0/*,[f7fa2687/84'/1'/0']tprv8ftRxc6xTpRsmi2MVzFhF5NiJiG8vPWGLZyaMZ4Y86VyPSHKYv2PySV9fTg4obY3Gchx7211p5eg7kMrG7ct6gxWYEUUvvxyisHKCZ9vhnX/0/*
```
represents the three extended keys. Notice the final key is an `xprv` and represents the nodes designated seed. The order of these keys is highly significant and it is crucial to note that the order matters very much. For example when we recover multi-sig wallets *FN2* knows the order as described above and will swap out the offline seed's `xpub` for an `xprv` and will swap the node's `xprv` for the `xpub`. If these keys are added in the incorrect order the wallet will create different addresses.
`[10c791f9/84'/1'/0']` this section of the extended key represents the derivation path, where `10c791f9` represents the master key fingerprint for that seed. Altogether we are telling bitcoin core that this extended key is a BIP84 testnet account extended key. The appended `/0/*` denotes the remaining path components with the `*` representing the keys we actually want to derive and import into the node.

Remember when we initially create the wallet with `bitcoin-cli createwallet` we tell the node to create the wallet with a blank keypool.

*FN2* after constructing the above BIP84 testnet multi-sig descriptor will then issue a `bitcoin-cli getdescriptorinfo` command to your node which returns a result such as:

```
Result:
{
  "descriptor" : "desc",         (string) The descriptor in canonical form, without private keys
  "checksum" : "chksum",         (string) The checksum for the input descriptor
  "isrange" : true|false,        (boolean) Whether the descriptor is ranged
  "issolvable" : true|false,     (boolean) Whether the descriptor is solvable
  "hasprivatekeys" : true|false, (boolean) Whether the input descriptor contained at least one private key
}
```

In order to actually import the keys into your node *FN2* then appends the `checksum` to the original descriptor and issues another command `bitcoin-cli importmulti` with the following parameters:

```
[{ "desc": "wsh(multi(2,[10c791f9/84'/1'/0']tpubDCDH16GTAZQojSwiTbDsjJLf5GqCHacQQvG4A1rgJiH5bVwkyhcALaZbFdAoYzJDuL5p1z4uJw47W57oAMjG7M1FMLzeVvoESXQhcK3iV9a/0/*,[183d7575/84'/1'/0']tpubDCT7BpTfsrYKwtcErnu32pMdsphzCdXJkdECmgnKQeYWvfci2bKN1TGgqGqLCY2ciT4VcRymqvZJnLrCyiqZryzYhcT5RCZTt5kPEEZv3vu/0/*,[f7fa2687/84'/1'/0']tprv8ftRxc6xTpRsmi2MVzFhF5NiJiG8vPWGLZyaMZ4Y86VyPSHKYv2PySV9fTg4obY3Gchx7211p5eg7kMrG7ct6gxWYEUUvvxyisHKCZ9vhnX/0/*))#2ctx5x3a", "timestamp": "now", "range": [0,2500], "watchonly": true, "label": "StandUp", "keypool": false, "internal": false }], {"rescan": false}]
```

Once we get a success response from your node that the 2500 primary keys have been imported into your node's wallet we then repeat the above process to also import the BIP84 change keys into the node, that involves changing the path to comply with BIP84/44/49 by changing the appended path `/0/*` to `/1/*`. This requires a second `getdescriptorinfo` command to get the proper checksum and another `importmulti` command with the following parameters to import the change keys into the node:

```
[{ "desc": "wsh(multi(2,[10c791f9/84'/1'/0']tpubDCDH16GTAZQojSwiTbDsjJLf5GqCHacQQvG4A1rgJiH5bVwkyhcALaZbFdAoYzJDuL5p1z4uJw47W57oAMjG7M1FMLzeVvoESXQhcK3iV9a/1/*,[183d7575/84'/1'/0']tpubDCT7BpTfsrYKwtcErnu32pMdsphzCdXJkdECmgnKQeYWvfci2bKN1TGgqGqLCY2ciT4VcRymqvZJnLrCyiqZryzYhcT5RCZTt5kPEEZv3vu/1/*,[f7fa2687/84'/1'/0']tprv8ftRxc6xTpRsmi2MVzFhF5NiJiG8vPWGLZyaMZ4Y86VyPSHKYv2PySV9fTg4obY3Gchx7211p5eg7kMrG7ct6gxWYEUUvvxyisHKCZ9vhnX/1/*))#cdhjhfs7", "timestamp": "now", "range": [0,2500], "watchonly": true, "label": "StandUp", "keypool": false, "internal": false }], {"rescan": false}]
```
Notice the appended path and the checksum are the only differences.

It is worth noting Bitcoin Core does not work especially well with multi-sig wallets which is why we have to set the `keypool` and `internal` arguments to false as your node will not add multi-sig addresses to its keypool. *FN2* picks up the slack here from Bitcoin Core and keeps track of your wallets index so that we can derive primary and change addresses on demand without reusing addresses.

Once the above process completes *FN2* will display a wallet created confirmation screen where you may save the Recovery QR and offline seed. Once you have confirmed to have saved those items you may receive to and spend from the wallet.

##### Single-sig wallets

For single-sig wallets we simply convert your devices seed to an account `xpub` depending on whether it is BIP84/44/49.

We repeat a similar process as above but because it is a single-sig wallet we only import the `xpub` and we can set `keypool` to `true` and `internal` to `true` as well when importing keys. See these two `importmulti` commands as an example for single-sig key importing:

For your primary keys:

```
bitcoin-cli importmulti [{ "desc": "wpkh([6010283d/84'/1'/0']tpubDC9yDKwrjmyBGAdWdhpVn1rtiQR7vgZ4FUzHbC8b1aQTwRBAVtBcon8iaamPGq9NiH2yCV3bLp6ZAWsNntcVYeWBX7fBzTmL2T6f2EcbxDi/0/*)#nv2ykqr0", "timestamp": "now", "range": [0,2500], "watchonly": true, "label": "StandUp", "keypool": true, "internal": false }]
```

For your change keys:

```
bitcoin-cli importmulti [{ "desc": "wpkh([6010283d/84'/1'/0']tpubDC9yDKwrjmyBGAdWdhpVn1rtiQR7vgZ4FUzHbC8b1aQTwRBAVtBcon8iaamPGq9NiH2yCV3bLp6ZAWsNntcVYeWBX7fBzTmL2T6f2EcbxDi/1/*)#zc09t4nh", "timestamp": "now", "range": [0,2500], "watchonly": true, "keypool": true, "internal": true }]
```

Notice this is still a BIP84 derivation but because it is single-sig we use `wpkh` (witness public key hash) instead of its multi-sig equivalent `wsh`. We actually to import the keys into the keypool and we only import the `xpub` so it is truly a watch-only wallet as far as the node is concerned.

#### Receiving

To generate addresses to receieve to in *FN2* we take two approaches, one for each wallet type.

##### Single-sig

For single-sig it is straightforward, we completely rely on your node to handle it a it created the wallet with `avoid_reuse` set to true and has the actual key in its keypool we can do that.

It is simply a matter of `bitcoin-cli getnewaddress` with an argument of either `legacy`, `bech32` or `p2sh-segwit` depending on your wallets derivation scheme. It is worth noting your node is capable of producing any address type for the public keys you imported into it. However from *FN2* point of view we specifiy a specific wallet derivation scheme so the user knows exactly what they are dealing with.

##### Mutli-sig

Again as Bitcoin Core is not designed to work especially well with multi-sig *FN2* has to handle some more wallet logic to generate receive addresses. *FN2* makes sure to keep careful track of the last used index, every time you use your wallet or go to the wallets tab *FN2* fetches each wallets UTXO's and checks the UTXO addresses path to ensure the wallet's index property is not set lower then the highest UTXO index. This way you may use the wallet outside of *FN2* and *FN2* will still never reuse a multi-sig address.

When you tap the "In" tab for a multi-sig wallet *FN2* will fetch the wallet last used index and increment it up by one, it will also fetch the wallets public key descriptor and then issue the following command to your node:

```
bitcoin-cli deriveaddresses ["wsh(multi(2,[77b83f20/84'/1'/0']tpubDDM9BgS5v4tKDLQiaQtSkE6W6nLxttAYU7kTjojb7dxm8kV99kmkUn3nPNpovJJAXoiFaAeA4zZWQCjZuU378SvDdVfBigkSJn5Ewtz3pCN/0/*,[dc0e74ad/84'/1'/0']tpubDCqkVqKYk9NWKxT7VxNCyEDETA12wWUDi6qn6rwevojQAxibuzUoowLMcFLaNGhqbrXrfLzkPoN8zRbxuHmGy9zkucJZqY6nraZe5kNY4mX/0/*,[e63243e5/84'/1'/0']tpubDDLDujmVccWCodNZzyqwE1sy5w4NfsrksyvnEU7P22KPJc4jw2epNZ56oUxVCV9rCAUdofcxKqy84iB2NNs1TcUjSZktNNr9qkeg6pbc9Yf/0/*))#097dvlk5", [2520,2520]]
```

Notice the `[2520,2520]`, this is the range where we can tell your node to derive all of these addresses. Since we only want one address to receive to at a time we specify the same index. Every time you generate an address in this way we update your wallet's index. We also always update your wallets' index every time you create a transaction, again we do this to avoid any possibility of reusing the same multi-sig address.

#### Spending

For both wallet types *FN2* will utilize the `bitcoin-cli walletcreatefundedpsbt` command.

For multi-sig wallets because Bitcoin Core does not add multi-sig keys to the keypool we need to first fetch a change address in the same way we fetch a receive address. *FN2* also saves your wallets change descriptor and will go ahead and use `deriveaddresses` for your wallets current index + 1 using the change descriptor instead of the primary descriptor.

Once a change address is created we use:

```
bitcoin-cli walletcreatefundedpsbt [[], {"tb1qlesv3vv5zlu6gzha53xhdu4kpzuqr60gxeyhr94jegktj9laxguq5pe49v": 0.0001}, 0, {"includeWatching": true, "replaceable": true, "conf_target": 2, "changeAddress": "tb1qn7lkzrylfyhz9lm6mqnmwlgpavcq7qs9ctxpsyjuaky4zuzr5x2qxrw069"}, true]
```

For single-sig wallets we do not need to specify a change address, instead we simply specify a `change_type` which conforms to the wallet's derivation. We do this because by default bitcoind will use a `p2sh-segwit` format address for change, yet it is important that we keep all the wallets inputs to conform with the wallet derivation scheme. The other difference is when it comes to signing for some reason LibWally has a bug where it will not sign single-sig psbt's, therefore we convert the psbt to an unsigned raw transaction and then sign the transaction locally with the appropriate private key.

- `[]` which is an empty array of inputs tells the node to handle coin selection for us which leverages Bitcoin Core's sophisticated coin selection algorithm. Whenever you itilize the sweep to tool we will simply fetch all of the wallets UTXO's from your node parse them and add them as inputs here
- `{"tb1qlesv3vv5zlu6gzha53xhdu4kpzuqr60gxeyhr94jegktj9laxguq5pe49v": 0.0001}` is our output.
- `0` is our locktime.
- `"includeWatching": true` as our node's wallets are always watch-only.
- `"replaceable": true` to ensure we can use RBF if needed.
- `"conf_target": 2` this represents the mining fee target you can set in *FN2* settings. It tells the node how many blocks we want the transaction to be confirmed in. This allows *FN2* to leverage Bitcoin Core's fee optimization.
- `"changeAddress": "tb1qn7lkzrylfyhz9lm6mqnmwlgpavcq7qs9ctxpsyjuaky4zuzr5x2qxrw069"` here we specify the change address we want to use which was initially fetched before building the `psbt`.

The node will then respond with a `psbt`, *FN2* takes that `psbt` and issues a second command to the node:

```
bitcoin-cli walletprocesspsbt ["cHNidP8BAIkCAAAAAd7uRtRwGBZSW7qrrIlwfxlmKozNGbd9Gy4ZQNeFpd3oAAAAAAD9////AlbBDwAAAAAAIgAgn79hDJ9JLiL/etgnt30B6zAPAgXCzBgSXO2JUXBDoZQQJwAAAAAAACIAIP5gyLGUF/mkCv2kTXbytgi4AenoNklxlrLKLLkX/TI4AAAAAAABASsx6Q8AAAAAACIAIKvuCzMLCyyw70Qm2zY48KG54nH+QQlQMRjg2jdBp5DtAQVpUiECcKUM+E4AR+y7zm2kYeXxJYXd3ytLdrcr6XT+oKXtaZ4hAhvjMJ6ZhLAUXtzrPn7lloCSYiCD7SdEeJb42SqqkTeiIQMnwBac6tHVFuIErUHuvFlFg+cb6yHF4LOgiD+8fF3OolOuIgYCG+MwnpmEsBRe3Os+fuWWgJJiIIPtJ0R4lvjZKqqRN6IY3A50rVQAAIABAACAAAAAgAEAAADRCQAAIgYCcKUM+E4AR+y7zm2kYeXxJYXd3ytLdrcr6XT+oKXtaZ4Yd7g/IFQAAIABAACAAAAAgAEAAADRCQAAIgYDJ8AWnOrR1RbiBK1B7rxZRYPnG+shxeCzoIg/vHxdzqIY5jJD5VQAAIABAACAAAAAgAEAAADRCQAAAAEBaVIhAmPcWcmdikDkPgwK+7NTMy+LgYIdbaGLthKX5sh0bfnhIQMxjckX2OwSv2q2JohrNs62Sq3O8Uff3t71n7DmiCC1EiEDSptrn3vKdwBT5474wGPUuyJsgx1KJ7gWEO9a/lgbM/JTriICAmPcWcmdikDkPgwK+7NTMy+LgYIdbaGLthKX5sh0bfnhGHe4PyBUAACAAQAAgAAAAIABAAAA2QkAACICAzGNyRfY7BK/arYmiGs2zrZKrc7xR9/e3vWfsOaIILUSGNwOdK1UAACAAQAAgAAAAIABAAAA2QkAACICA0qba597yncAU+eO+MBj1LsibIMdSie4FhDvWv5YGzPyGOYyQ+VUAACAAQAAgAAAAIABAAAA2QkAAAABAWlSIQJ4DaqZKYHp4ni9Com5K4fMldgJ7dmfH8hZd2uIiq9jwiEDrqtuo68Jty4mjmFe68AZzogMTviOVFBqqG0EzK1bC1ghAsJGkJTs32gEDxQrThcv/PfQsalhTO8y29JBVSA+iGqWU64iAgJ4DaqZKYHp4ni9Com5K4fMldgJ7dmfH8hZd2uIiq9jwhh3uD8gVAAAgAEAAIAAAACAAAAAANkJAAAiAgLCRpCU7N9oBA8UK04XL/z30LGpYUzvMtvSQVUgPohqlhjmMkPlVAAAgAEAAIAAAACAAAAAANkJAAAiAgOuq26jrwm3LiaOYV7rwBnOiAxO+I5UUGqobQTMrVsLWBjcDnStVAAAgAEAAIAAAACAAAAAANkJAAAA", true, "ALL", true]
```
The `walletprocesspsbt` tells our node to sign the `psbt` if it can, it will then sign and return the resulting partially signed `psbt`. At this point *FN2* will decode the `psbt` to see fetch the bip32 path for the inputs. From the input we can get the UTXO's index, from that index we fetch the same private key from its respective path and the device then signs the `psbt` locally. At this point the `psbt` should be fully signed.

After the device fully signs the `psbt` we `finalize` it locally using LibWally which converts it from `psbt` format to a raw transaction.

Your node will then decode the signed raw transaction, parse each input, output and calculate the mining fee to be paid by totaling the inputs and outputs, subtracting the total from each other.

This list of inputs/outputs and the mining fee is then displayed to the user for confirmation before being broadcast. *FN2* allows you to tap each input and output, doing this runs the `bitcoin-cli getaddressinfo` command and fetches whatever info the node's wallet knows about the respective address. In this way users can verify without a doubt that the input belongs to them, the change output belongs to them and that the recipient does or doesn't belong to them.

Once the user is happy everything looks good they can tap `broadcast` at which point the node will broadcast the transaction.

It is worth noting the app is fully capable of creating unsigned transactions and if for some reason your node can not sign the transaction of you delete the seed from your device *FN2* will instead create an unsigned transaction and instead of broadcasting it will display a list of options for formatting the unsigned transaction to export to a variety of offline signers such as Coldcard, Hermit etc.

### Wishlist

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

### Requirements

- iOS 13
- A Bitcoin Core full node v0.19.0.1 (at minimum) which is running on Tor with `rpcport` exposed to a Tor V3 hidden service. Your node does not need to be an archive node, thus you can save space by being setup as a pruned full node.

### Build From Source

##### Install Brew

Run `brew --version` in a terminal, if you get a valid response you have brew installed already, if not:

```
cd /usr/local
mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
```
Wait for bew to finish.

##### Install carthage

Follow these [instructions](https://brewinstall.org/install-carthage-on-mac-with-brew/)

##### Install XCode

- [Install Xcode](https://itunes.apple.com/id/app/xcode/id497799835?mt=12)
- You will need a free Apple developer account create one [here](https://developer.apple.com/programs/enroll/)
- In XCode, click "XCode" -> "preferences" -> "Accounts" -> add your github account
- Go to the [repo](https://github.com/BlockchainCommons/FullyNoded-2) click `Clone and Download` -> `Open in XCode`
- Once it opens go ahead an close it for now and quit XCode

##### Install Tor.Framework Dependencies

These steps will ensure Tor.framework builds successfully, it will create a completely separate Tor.framework directory on your machine which should not be confused with *FN2* or it's Tor.framework.

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
It is normal to see an error about XCFrameworks in the above process. It can be ignored.

Once the above process completes you can:
```
cd <into FullyNoded 2>
carthage update --platform iOS
```

##### Install LibWally-Swift with Cocoapods

- If you don't have Cocoapods install it with `sudo gem install cocoapods`
- `cd <into the project>` (FullyNoded 2)
- run `pod install`
- If you run into an error you may need to follow the instructions from [LibWally-Swift](https://github.com/blockchain/libwally-swift) in order for it to build.
- Upon first running FullyNoded 2 you will most likely need to make a few variables `public` in LibWally-Swift, this is because the way the app works requires us to get access to private keys to sign transactions with and psbt input paths in order to fetch private keys for signing. You will see a `X not accessible due to internal protection` error, simply go to that variable make it public then run the project again in XCode.

### Principal Architect
- Christopher Allen [@ChristopherA](https://github.com/@ChristopherA) \<ChristopherA@LifeWithAlacrity.com\>

### Project Lead
- Peter Denton [@Fonta1n3](https://github.com/Fonta1n3) \<fonta1n3@protonmail.com\>
- GPG Fingerprint: 3B37 97FA 0AE8 4BE5 B440  6591 8564 01D7 121C 32FC

### Authors
- Add your name here by getting involved, first step is to check out our [contributing section](https://github.com/BlockchainCommons/FullyNoded-2#contributing).

### Reporting a Vulnerability

To report security issues send an email to ChristopherA@LifeWithAlacrity.com (not for support).

The following keys may be used to communicate sensitive information to developers:

| Name              | Fingerprint                                        |
| ----------------- | -------------------------------------------------- |
| Christopher Allen | FDFE 14A5 4ECB 30FC 5D22  74EF F8D3 6C91 3574 05ED |

You can import a key by running the following command with that individual’s fingerprint: `gpg --recv-keys "<fingerprint>"` Ensure that you put quotes around fingerprints that contain spaces.

### Built with
- [Tor.framework](https://github.com/iCepa/Tor.framework) by the [iCepa project](https://github.com/iCepa) - for communicating with your nodes hidden service
- [LibWally-Swift](https://github.com/blockchain/libwally-swift) built by [@Sjors](https://github.com/Sjors) - for BIP39 mnemonic creation and HD key derivation
- [Base32](https://github.com/norio-nomura/Base32/blob/master/Sources/Base32) built by [@norio-nomura](https://github.com/norio-nomura) - for Tor V3 authentication key encoding
- [Keychain-Swift](https://github.com/evgenyneu/keychain-swift) built by [@evgenyneu](https://github.com/evgenyneu) for securely storing sensitive data on your devices keychain

### Copyright & License

This code in this repository is Copyright © 2019 by Blockchain Commons, LLC, and is [licensed](./LICENSE) under the [spdx:BSD-2-Clause Plus Patent License](https://spdx.org/licenses/BSD-2-Clause-Patent.html).

### Contributing

We encourage public contributions through issues and pull-requests! Please review [CONTRIBUTING.md](./CONTRIBUTING.md) for details on our development process. All contributions to this repository require a GPG signed [Contributor License Agreement](./CLA.md).
