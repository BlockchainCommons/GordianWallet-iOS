# How Does Gordian Wallet Work?

*Gordian Wallet* operates in tandem with your node; for every wallet that you create with *Gordian Wallet*, a corresponding `wallet.dat` file will be created on your node using the `bitcoin-cli createwallet` command. Wallets will not be saved locally to your device until it is 100% confirmed that the wallet and its keys were successfully imported into your node.

## Wallet Creation

*Gordian Wallet* is currently capable of creating two core wallet types: single-sig wallets and 2-of-3 multi-sig wallets.

*Gordian Wallet* creates its wallets on your full-node server using the following commands:

*Single-sig wallets:*

`bitcoin-cli createwallet <your wallet name>, true, true, "", true`

*Multi-sig wallets:*

`bitcoin-cli createwallet <your wallet name>, false, true, "", true`

The five arguments can be viewed in the Bitcoin Core v0.19.1 help for `createwallet`:

```
Arguments:
1. wallet_name             (string, required) The name for the new wallet. If this is a path, the wallet will be created at the path location.
2. disable_private_keys    (boolean, optional, default=false) Disable the possibility of private keys (only watchonlys are possible in this mode).
3. blank                   (boolean, optional, default=false) Create a blank wallet. A blank wallet has no keys or HD seed. One can be set using sethdseed.
4. passphrase              (string) Encrypt the wallet with this passphrase.
5. avoid_reuse             (boolean, optional, default=false) Keep track of coin reuse, and treat dirty and clean coins differently with privacy considerations in mind.
```
More generally:

- 1. `<your wallet name>`: a SHA256 hash of your wallets public key descriptor. You can think of your public key descriptor as a unique fingerprint for your wallet: no two will ever be the same. This means that *Gordian Wallet* can name wallets deterministically, based on the descriptor which holds all the information necessary to derive your wallet's addresses. When you go to recover a wallet, *Gordian Wallet* will first create your descriptor and get its hash to see if the wallet already exists on your node or not.

- 2. `disable_private_keys`: `true` or `false`: the first boolean lets the node know that *Gordian Wallet* wants to create the wallet with `disable_private_keys` set to true for single-sig wallets and `false` for multi-sig wallets. This means that for a single-sig wallet, the node never holds any private keys at all. For multi-sig wallets, the node is a signer and holds 5,000 private keys derived from your node's designated seed.

- 3.  `blank`: `true`: the second boolean lets the node know that *Gordian Wallet* wants the wallet to be created with a blank keypool so that *Gordian Wallet* is 100% in control over which keys the node's wallet "knows about".

- 4. `passphrase`: `""`: the fourth argument as an empty string tells the node that *Gordian Wallet* does not want to encrypt the wallet with a passphrase. This can be done at a later time by the user if desired. If you do encrypt your wallet you will need to decrypt it before *Gordian Wallet* will be able to function normally.

- 5. `avoid_reuse`: `true`: the fifth and final boolean argument lets the node know that *Gordian Wallet* wants to avoid reusing any addresses, as that is a best practice. *Gordian Wallet* is smart enough to do this on its own but as your wallet also "exists" on your node you do always have the option of using this wallet without *Gordian Wallet* at all — which is why we take extra precautions to avoid any risk of address reuse.

## Key Creation

Before we ever create the wallet on your , *Gordian Wallet* will first create the seeds locally on the device using your device's cryptographically secure random number generator.

For single-sig wallets a single seed is created, encrypted, and stored locally.

For multi-sig wallets, three seeds are initially created.

- 1. The first seed is designated as your offline recovery phrase and converted into a 12-word BIP39 mnemonic that you are responsible for storing offline. This mnemonic *must* be saved and used in order to refill your node's wallet's keypool and to recover the wallet if you lose your node or delete the wallet from the node somehow. Once you go through the wallet-created confirmation flow, the offline seed will be deleted from the device forever; it is never stored on the device's database, it is displayed temporarily to give you a chance to save it, then removed entirely.

- 2. The second seed is designated as your device's seed and is securely encrypted and stored locally. This seed may be exported at any time along with the Recovery QR code that itself holds this seed.

- 3. The third seed is designated for the node. It is converted to an `xprv` then the seed itself is deleted forever from the device. It is never stored to the device's database.

At this stage the device is fully capable of signing transactions for the wallet. In order for the node to be able to sign transactions or create PSBTs, we need to import keys into it.

## Key importing

### Multi-sig wallets

For multi-sig wallets the device converts seed #1 and #2 to xpubs and seed #3 to an xprv. *Gordian Wallet* then constructs a descriptor, which for a BIP84 wallet would look like this:

```
"wsh(multi(2,[10c791f9/84'/1'/0']tpubDCDH16GTAZQojSwiTbDsjJLf5GqCHacQQvG4A1rgJiH5bVwkyhcALaZbFdAoYzJDuL5p1z4uJw47W57oAMjG7M1FMLzeVvoESXQhcK3iV9a/0/*,[183d7575/84'/1'/0']tpubDCT7BpTfsrYKwtcErnu32pMdsphzCdXJkdECmgnKQeYWvfci2bKN1TGgqGqLCY2ciT4VcRymqvZJnLrCyiqZryzYhcT5RCZTt5kPEEZv3vu/0/*,[f7fa2687/84'/1'/0']tprv8ftRxc6xTpRsmi2MVzFhF5NiJiG8vPWGLZyaMZ4Y86VyPSHKYv2PySV9fTg4obY3Gchx7211p5eg7kMrG7ct6gxWYEUUvvxyisHKCZ9vhnX/0/*))"
```
`wsh` represents the address format, in this case "witness script hash".
`multi` represents a multi-sig type descriptor.
`2` represents the number of signatures required to spend from this wallet.

The rest of the information represents the three extended keys:
```
[10c791f9/84'/1'/0']tpubDCDH16GTAZQojSwiTbDsjJLf5GqCHacQQvG4A1rgJiH5bVwkyhcALaZbFdAoYzJDuL5p1z4uJw47W57oAMjG7M1FMLzeVvoESXQhcK3iV9a/0/*,[183d7575/84'/1'/0']tpubDCT7BpTfsrYKwtcErnu32pMdsphzCdXJkdECmgnKQeYWvfci2bKN1TGgqGqLCY2ciT4VcRymqvZJnLrCyiqZryzYhcT5RCZTt5kPEEZv3vu/0/*,[f7fa2687/84'/1'/0']tprv8ftRxc6xTpRsmi2MVzFhF5NiJiG8vPWGLZyaMZ4Y86VyPSHKYv2PySV9fTg4obY3Gchx7211p5eg7kMrG7ct6gxWYEUUvvxyisHKCZ9vhnX/0/*
```
The first section of the extended key, such as `[10c791f9/84'/1'/0']` represents the derivation path, where `10c791f9` represents the master key fingerprint for that seed. In this example, we are telling Bitcoin Core that this extended key is a BIP84 testnet account extended key. The appended `/0/*` denotes the remaining path components with the `*` representing the keys we actually want to derive and import into the node.

Notice the final key is an `xprv` and represents the node's designated seed. The order of these keys is highly significant, and it is crucial to note that the order matters very much. For example, when we recover multi-sig wallets, *Gordian Wallet* knows the order as described above and will swap out the offline seed's `xpub` for an `xprv` and will swap the node's `xprv` for the `xpub`. If these keys are added in the incorrect order, the wallet will create different addresses.

Remember that when we initially create the wallet with `bitcoin-cli createwallet` we tell the node to create the wallet with a blank keypool.

After constructing the above BIP84 testnet multi-sig descriptor, *Gordian Wallet*  will then issue a `bitcoin-cli getdescriptorinfo` command to your node which returns a result such as:

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

In order to actually import the keys into your node, *Gordian Wallet* then appends the `checksum` to the original descriptor and issues another command `bitcoin-cli importmulti` with the following parameters:

```
[{ "desc": "wsh(multi(2,[10c791f9/84'/1'/0']tpubDCDH16GTAZQojSwiTbDsjJLf5GqCHacQQvG4A1rgJiH5bVwkyhcALaZbFdAoYzJDuL5p1z4uJw47W57oAMjG7M1FMLzeVvoESXQhcK3iV9a/0/*,[183d7575/84'/1'/0']tpubDCT7BpTfsrYKwtcErnu32pMdsphzCdXJkdECmgnKQeYWvfci2bKN1TGgqGqLCY2ciT4VcRymqvZJnLrCyiqZryzYhcT5RCZTt5kPEEZv3vu/0/*,[f7fa2687/84'/1'/0']tprv8ftRxc6xTpRsmi2MVzFhF5NiJiG8vPWGLZyaMZ4Y86VyPSHKYv2PySV9fTg4obY3Gchx7211p5eg7kMrG7ct6gxWYEUUvvxyisHKCZ9vhnX/0/*))#2ctx5x3a", "timestamp": "now", "range": [0,2500], "watchonly": true, "label": "StandUp", "keypool": false, "internal": false }], {"rescan": false}]
```

Once *Gordian Wallet* gets a success response from the node that the 2500 primary keys have been imported into the node's wallet, we then repeat the above process to also import the BIP84 change keys into the node. This involves adjusting the path to comply with BIP84/44/49 by changing the appended path `/0/*` to `/1/*`. This requires a second `getdescriptorinfo` command to get the proper checksum and another `importmulti` command with the following parameters to import the change keys into the node:

```
[{ "desc": "wsh(multi(2,[10c791f9/84'/1'/0']tpubDCDH16GTAZQojSwiTbDsjJLf5GqCHacQQvG4A1rgJiH5bVwkyhcALaZbFdAoYzJDuL5p1z4uJw47W57oAMjG7M1FMLzeVvoESXQhcK3iV9a/1/*,[183d7575/84'/1'/0']tpubDCT7BpTfsrYKwtcErnu32pMdsphzCdXJkdECmgnKQeYWvfci2bKN1TGgqGqLCY2ciT4VcRymqvZJnLrCyiqZryzYhcT5RCZTt5kPEEZv3vu/1/*,[f7fa2687/84'/1'/0']tprv8ftRxc6xTpRsmi2MVzFhF5NiJiG8vPWGLZyaMZ4Y86VyPSHKYv2PySV9fTg4obY3Gchx7211p5eg7kMrG7ct6gxWYEUUvvxyisHKCZ9vhnX/1/*))#cdhjhfs7", "timestamp": "now", "range": [0,2500], "watchonly": true, "label": "StandUp", "keypool": false, "internal": false }], {"rescan": false}]
```
Notice the appended path and the checksum are the only differences.

Once the above process completes, *Gordian Wallet* will display a wallet created confirmation screen where you may save the Recovery QR and offline seed. Once you have confirmed that you have saved those items, you may receive to and spend from the wallet.

It is worth noting Bitcoin Core does not work especially well with multi-sig wallets, which is why we have to set the `keypool` and `internal` arguments to false, as your node will not add multi-sig addresses to its keypool. *Gordian Wallet* picks up the slack here from Bitcoin Core and keeps track of your wallet's index so that we can derive primary and change addresses on demand without reusing addresses.

### Single-sig wallets

For single-sig wallets, *Gordian Wallet* simply converts your device's seed to an account `xpub` depending on whether it is BIP84/44/49.

It uses a similar process as above, but because it is a single-sig wallet we only import the `xpub` and we can set `keypool` to `true` and `internal` to `true` as well when importing keys. See these two `importmulti` commands as an example for single-sig key importing:

For your primary keys:

```
bitcoin-cli importmulti [{ "desc": "wpkh([6010283d/84'/1'/0']tpubDC9yDKwrjmyBGAdWdhpVn1rtiQR7vgZ4FUzHbC8b1aQTwRBAVtBcon8iaamPGq9NiH2yCV3bLp6ZAWsNntcVYeWBX7fBzTmL2T6f2EcbxDi/0/*)#nv2ykqr0", "timestamp": "now", "range": [0,2500], "watchonly": true, "label": "StandUp", "keypool": true, "internal": false }]
```

For your change keys:

```
bitcoin-cli importmulti [{ "desc": "wpkh([6010283d/84'/1'/0']tpubDC9yDKwrjmyBGAdWdhpVn1rtiQR7vgZ4FUzHbC8b1aQTwRBAVtBcon8iaamPGq9NiH2yCV3bLp6ZAWsNntcVYeWBX7fBzTmL2T6f2EcbxDi/1/*)#zc09t4nh", "timestamp": "now", "range": [0,2500], "watchonly": true, "keypool": true, "internal": true }]
```

Notice this is still a BIP84 derivation but because it is single-sig we use `wpkh` (witness public key hash) instead of its multi-sig equivalent `wsh`. We only import the `xpub` so it is truly a watch-only wallet as far as the node is concerned.

## Receiving Funds

To generate addresses to receieve funds in *Gordian Wallet* we take two approaches, one for each wallet type.

### Single-sig Wallets

For single-sig wallets, receiving funds is straightforward: we completely rely on the node to handle it, as *Gordian Wallet* created the wallet with `avoid_reuse` set to true and the node's wallet holds the derived keys in its keypool.

It is simply a matter of running `bitcoin-cli getnewaddress` with an argument of either `legacy`, `bech32` or `p2sh-segwit` depending on your wallet's derivation scheme. It is worth noting that the node is capable of producing any address type for the public keys you imported into it. However from *Gordian Wallet's* point of view, we specifiy a specific wallet derivation scheme so the user knows exactly what they are dealing with.

### Mutli-sig Wallets

Again, since Bitcoin Core is not designed to work especially well with multi-sigs, *Gordian Wallet* has to handle some more wallet logic to generate receive addresses. *Gordian Wallet* makes sure to keep careful track of the last used index: every time you use your wallet or go to the wallet's tab *Gordian Wallet* fetches each wallet's UTXOs and checks the UTXO addresses path to ensure the wallet's index property is not set lower then the highest UTXO index. This way, you may use the wallet outside of *Gordian Wallet* and *Gordian Wallet* will still never reuse a multi-sig address.

When you tap the "In" tab for a multi-sig wallet *Gordian Wallet* will fetch the wallet's last used index and increment it by one. It will also fetch the wallets' public key descriptor and then issue the following command to the node:

```
bitcoin-cli deriveaddresses ["wsh(multi(2,[77b83f20/84'/1'/0']tpubDDM9BgS5v4tKDLQiaQtSkE6W6nLxttAYU7kTjojb7dxm8kV99kmkUn3nPNpovJJAXoiFaAeA4zZWQCjZuU378SvDdVfBigkSJn5Ewtz3pCN/0/*,[dc0e74ad/84'/1'/0']tpubDCqkVqKYk9NWKxT7VxNCyEDETA12wWUDi6qn6rwevojQAxibuzUoowLMcFLaNGhqbrXrfLzkPoN8zRbxuHmGy9zkucJZqY6nraZe5kNY4mX/0/*,[e63243e5/84'/1'/0']tpubDDLDujmVccWCodNZzyqwE1sy5w4NfsrksyvnEU7P22KPJc4jw2epNZ56oUxVCV9rCAUdofcxKqy84iB2NNs1TcUjSZktNNr9qkeg6pbc9Yf/0/*))#097dvlk5", [2520,2520]]
```

Notice the `[2520,2520]`. This is the range from which *Gordian Wallet* tells the node to derive all of these addresses. Since we only want one address to receive to at a time, we specify the same index. Every time you generate an address in this way, *Gordian Wallet* updates your wallet's index. It also always updates your wallet's index every time you create a transaction. Again, we do this to avoid any possibility of reusing the same multi-sig address.

## Spending Funds

For both wallet types, *Gordian Wallet* will prepare to spend funds using the `bitcoin-cli walletcreatefundedpsbt` command.

For multi-sig wallets *Gordian Wallet* needs to first fetch a change address in the same way it fetches a receive address (because Bitcoin Core does not add multi-sig keys to the keypool). *Gordian Wallet* also saves your wallet's change descriptor and will go ahead and use `deriveaddresses` for your wallet's current index + 1 using the change descriptor instead of the primary descriptor.

Once a change address is created for a multi-sig wallet, *Gordian Wallet* runs the command to create the PSBT:

```
bitcoin-cli walletcreatefundedpsbt [[], {"tb1qlesv3vv5zlu6gzha53xhdu4kpzuqr60gxeyhr94jegktj9laxguq5pe49v": 0.0001}, 0, {"includeWatching": true, "replaceable": true, "conf_target": 2, "changeAddress": "tb1qn7lkzrylfyhz9lm6mqnmwlgpavcq7qs9ctxpsyjuaky4zuzr5x2qxrw069"}, true]
```

For single-sig wallets, we do not need to specify a change address. Instead, we simply specify a `change_type` that conforms to the wallet's derivation. We do this because by default bitcoind will use a `p2sh-segwit` format address for change, yet it is important that we keep all the wallet's inputs in conformance with the wallet's derivation scheme. The other difference is when it comes to signing; for some reason, LibWally has a bug where it will not sign single-sig PSBTs, therefore we convert the PSBT to an unsigned raw transaction and then sign the transaction locally with the appropriate private key.

The arguments to `walletcreatefundedpsbt` are as follows:

- `[]`, which is an empty array of inputs, tells the node to handle coin selection for us, which leverages Bitcoin Core's sophisticated coin selection algorithm. Whenever you utilize the sweep-to tool, *Gordian Wallet* will simply fetch all of the wallets UTXOs from the node, parse them, and add them as inputs here
- `{"tb1qlesv3vv5zlu6gzha53xhdu4kpzuqr60gxeyhr94jegktj9laxguq5pe49v": 0.0001}` is our output.
- `0` is our locktime.
- `"includeWatching": true` says that our node's wallets are always watch-only.
- `"replaceable": true` ensures that we can use RBF if needed.
- `"conf_target": 2` represents the mining-fee target that you can set in *Gordian Wallet* settings. It tells the node how many blocks we want the transaction to be confirmed in. This allows *Gordian Wallet* to leverage Bitcoin Core's fee optimization.
- `"changeAddress": "tb1qn7lkzrylfyhz9lm6mqnmwlgpavcq7qs9ctxpsyjuaky4zuzr5x2qxrw069"` specifies the change address we want to use, which was initially fetched before building the PSBT.

The node will then respond with a `psbt`, *Gordian Wallet* takes that `psbt` and issues a second command to the node:

```
bitcoin-cli walletprocesspsbt ["cHNidP8BAIkCAAAAAd7uRtRwGBZSW7qrrIlwfxlmKozNGbd9Gy4ZQNeFpd3oAAAAAAD9////AlbBDwAAAAAAIgAgn79hDJ9JLiL/etgnt30B6zAPAgXCzBgSXO2JUXBDoZQQJwAAAAAAACIAIP5gyLGUF/mkCv2kTXbytgi4AenoNklxlrLKLLkX/TI4AAAAAAABASsx6Q8AAAAAACIAIKvuCzMLCyyw70Qm2zY48KG54nH+QQlQMRjg2jdBp5DtAQVpUiECcKUM+E4AR+y7zm2kYeXxJYXd3ytLdrcr6XT+oKXtaZ4hAhvjMJ6ZhLAUXtzrPn7lloCSYiCD7SdEeJb42SqqkTeiIQMnwBac6tHVFuIErUHuvFlFg+cb6yHF4LOgiD+8fF3OolOuIgYCG+MwnpmEsBRe3Os+fuWWgJJiIIPtJ0R4lvjZKqqRN6IY3A50rVQAAIABAACAAAAAgAEAAADRCQAAIgYCcKUM+E4AR+y7zm2kYeXxJYXd3ytLdrcr6XT+oKXtaZ4Yd7g/IFQAAIABAACAAAAAgAEAAADRCQAAIgYDJ8AWnOrR1RbiBK1B7rxZRYPnG+shxeCzoIg/vHxdzqIY5jJD5VQAAIABAACAAAAAgAEAAADRCQAAAAEBaVIhAmPcWcmdikDkPgwK+7NTMy+LgYIdbaGLthKX5sh0bfnhIQMxjckX2OwSv2q2JohrNs62Sq3O8Uff3t71n7DmiCC1EiEDSptrn3vKdwBT5474wGPUuyJsgx1KJ7gWEO9a/lgbM/JTriICAmPcWcmdikDkPgwK+7NTMy+LgYIdbaGLthKX5sh0bfnhGHe4PyBUAACAAQAAgAAAAIABAAAA2QkAACICAzGNyRfY7BK/arYmiGs2zrZKrc7xR9/e3vWfsOaIILUSGNwOdK1UAACAAQAAgAAAAIABAAAA2QkAACICA0qba597yncAU+eO+MBj1LsibIMdSie4FhDvWv5YGzPyGOYyQ+VUAACAAQAAgAAAAIABAAAA2QkAAAABAWlSIQJ4DaqZKYHp4ni9Com5K4fMldgJ7dmfH8hZd2uIiq9jwiEDrqtuo68Jty4mjmFe68AZzogMTviOVFBqqG0EzK1bC1ghAsJGkJTs32gEDxQrThcv/PfQsalhTO8y29JBVSA+iGqWU64iAgJ4DaqZKYHp4ni9Com5K4fMldgJ7dmfH8hZd2uIiq9jwhh3uD8gVAAAgAEAAIAAAACAAAAAANkJAAAiAgLCRpCU7N9oBA8UK04XL/z30LGpYUzvMtvSQVUgPohqlhjmMkPlVAAAgAEAAIAAAACAAAAAANkJAAAiAgOuq26jrwm3LiaOYV7rwBnOiAxO+I5UUGqobQTMrVsLWBjcDnStVAAAgAEAAIAAAACAAAAAANkJAAAA", true, "ALL", true]
```
The `walletprocesspsbt` tells the node to sign the `psbt` if it can. It will then sign and return the partially signed `psbt`. At this point, *Gordian Wallet* will decode the `psbt` to fetch the BIP32 path for the inputs. From the input's path *Gordian Wallet* can get the UTXO's address index and from that index it will fetch the corresponding private key. The device then signs the `psbt` locally with that private key. At this point, the `psbt` should be fully signed.

After the device fully signs the `psbt` Gordian Wallet `finalize`s it locally using LibWally, which converts it from `psbt` format to a raw transaction.

The node will then decode the signed raw transaction, parse each input and output, and calculate the mining fee to be paid by totaling the inputs and outputs, subtracting the total from each other.

This list of inputs/outputs and the mining fee is then displayed to the user for confirmation before being broadcast. *Gordian Wallet* allows you to tap each input and output. Doing this runs the `bitcoin-cli getaddressinfo` command and fetches whatever info the node's wallet knows about the respective address. In this way users can verify without a doubt that the input belongs to them, the change output belongs to them, and that the recipient does or doesn't belong to them.

Once the user is happy everything looks good, they can tap `broadcast`, at which point the node will broadcast the transaction.

It is worth noting that *Gordian Wallet* is fully capable of creating unsigned transactions. If for some reason the node can not sign the transaction or you delete the seed from your device, *Gordian Wallet* will instead create an unsigned transaction and instead of broadcasting it will display a list of options for formatting the unsigned transaction, to export to a variety of offline signers such as Coldcard, Hermit etc.

## Coin Control

Whenever you lock a utxo the app calls `bitcoin-cli lockunspent` so that your utxo is locked on the bitcoind level. The app keeps a local data store of each utxo you lock so that we can display useful information to you about that utxo after it is locked. The reason for this is that when you make the `bitcoin-cli listlockunspent` it only returns a `txid` and `vout` of the utxo which is not very useful for the average user. We simply store the utxo's metadata (number of confirmations, descriptor, amount, address etc) that is associated with that `txid` and `vout` (at the time of locking) locally so that we may better parse them. For example in order to unlock all change utxos we need to parse the descriptor of the utxo to see if it is a change utxo, to unlock all dust utxos we need to know what amount that utxo holds.

Locking change utxo's parses all unlocked utxo's, fetches the descritpor for each and checks the derivation path of the descriptor to see if it includes the internal path component as per BIP44/84/49/48 e.g. "/1/". If it does we know its change and can lock/unlock it.

If the user has locked utxo's outside of the app there is no way for us to (quickly) parse that utxo. This would not be an issue if we could guarantee a user only holds a small amount of utxo's as we could manually fetch each transaction via the `txid` and `vout`, yet if a user has say more then 10 utxos it can take Tor quite some time to fetch all that data and it quickly becomes impractical from there. For this reason if you have locked utxo's outside of the app you will see "?" marks where the labels would be. To update them you may unlock them and then lock them again with the app.
