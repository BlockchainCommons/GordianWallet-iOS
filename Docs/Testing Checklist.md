# Testing Checklist

#### To thouroughly test the wallets critical functionality before committing real funds to it we recommend the following steps as a general guide:

### Step 1:

- [ ] Create each possible wallet type, save the *Recovery QR* and *Recovery words* for each wallet
  - [ ] Create BIP84 multi-sig wallet
  - [ ] Create BIP44 multi-sig wallet
  - [ ] Create BIP49 multi-sig wallet
  - [ ] Create BIP84 single-sig wallet
  - [ ] Create BIP44 single-sig wallet
  - [ ] Create BIP49 single-sig wallet
  
### Step 2:
  
- [ ] Receive funds to each wallet
  - [ ] BIP84 multi-sig wallet
  - [ ] BIP44 multi-sig wallet
  - [ ] BIP49 multi-sig wallet
  - [ ] BIP84 single-sig wallet
  - [ ] BIP44 single-sig wallet
  - [ ] BIP49 single-sig wallet
  
### Step 3:

- [ ] Spend funds from each wallet. **Record the final balance and wallet name for verification later.**
  - [ ] BIP84 multi-sig wallet
  - [ ] BIP44 multi-sig wallet
  - [ ] BIP49 multi-sig wallet
  - [ ] BIP84 single-sig wallet
  - [ ] BIP44 single-sig wallet
  - [ ] BIP49 single-sig wallet
  
### Step 4:
  
- [ ] Delete each wallet from the device and your node
  - [ ] BIP84 multi-sig wallet
  - [ ] BIP44 multi-sig wallet
  - [ ] BIP49 multi-sig wallet
  - [ ] BIP84 single-sig wallet
  - [ ] BIP44 single-sig wallet
  - [ ] BIP49 single-sig wallet
  
### Step 5:

- [ ] Recover the single-sig wallets on *FN2* with the *Recovery QR*:
    "wallets" -> + -> "Recover Wallet" -> scan the *Recovery QR*
  - [ ] BIP84 single-sig wallet
  - [ ] BIP44 single-sig wallet
  - [ ] BIP49 single-sig wallet
  
### Step 6:
  
- [ ] Delete each recovered single-sig wallet from your device and node 
  - [ ] BIP84 single-sig wallet
  - [ ] BIP44 single-sig wallet
  - [ ] BIP49 single-sig wallet
  
### Step 7:

- [ ] Recover the single-sig wallets on *FN2* with the recovery words:
    "wallets" -> + -> "Recover Wallet" -> "I don't have one" and input your words (they may all be pasted in one go or input individually)
  - [ ] BIP84 single-sig wallet
  - [ ] BIP44 single-sig wallet
  - [ ] BIP49 single-sig wallet
  
### Step 8:
  
- [ ] Fully recover each multi-sig wallet using both the *Recovery QR* and recovery words:
    "wallets" -> + -> "Recover Wallet" -> scan the *Recovery QR* -> input the words
  - [ ] BIP84 multi-sig wallet
  - [ ] BIP44 multi-sig wallet
  - [ ] BIP49 multi-sig wallet
  
### Step 9:
  
- [ ] Delete each wallet from the device only.
  - [ ] BIP84 multi-sig wallet
  - [ ] BIP44 multi-sig wallet
  - [ ] BIP49 multi-sig wallet
  - [ ] BIP84 single-sig wallet
  - [ ] BIP44 single-sig wallet
  - [ ] BIP49 single-sig wallet
  
### Step 10:
    
- [ ] Recover each wallet with the *Recovery QR* only.
  - [ ] BIP84 multi-sig wallet
  - [ ] BIP44 multi-sig wallet
  - [ ] BIP49 multi-sig wallet
  - [ ] BIP84 single-sig wallet
  - [ ] BIP44 single-sig wallet
  - [ ] BIP49 single-sig wallet
  
### Step 11:

- [ ] Ensure each wallet name, type and balances match what you recorded in step 3.
  - [ ] BIP84 multi-sig wallet
  - [ ] BIP44 multi-sig wallet
  - [ ] BIP49 multi-sig wallet
  - [ ] BIP84 single-sig wallet
  - [ ] BIP44 single-sig wallet
  - [ ] BIP49 single-sig wallet
  
### Step 12:

- [ ] Spend from each wallet a final time to ensure full functionality after recovering in all possible scenarios.
  - [ ] BIP84 multi-sig wallet
  - [ ] BIP44 multi-sig wallet
  - [ ] BIP49 multi-sig wallet
  - [ ] BIP84 single-sig wallet
  - [ ] BIP44 single-sig wallet
  - [ ] BIP49 single-sig wallet
  
### Step 13:

  - [ ] Refill the keypool for each wallet:
    "wallets" -> "tools" -> "refill keypool" (for multi-sig wallets you will need the offline recovery words in order to refill the keypool)
    - [ ] BIP84 multi-sig wallet
    - [ ] BIP44 multi-sig wallet
    - [ ] BIP49 multi-sig wallet
    - [ ] BIP84 single-sig wallet
    - [ ] BIP44 single-sig wallet
    - [ ] BIP49 single-sig wallet
    
### Step 14:

- [ ] Utilize the "sweep to" tool for each wallet. This will ensure you can sweep funds out of a a compromised wallet and into a new setup.
  - [ ] BIP84 multi-sig wallet
  - [ ] BIP44 multi-sig wallet
  - [ ] BIP49 multi-sig wallet
  - [ ] BIP84 single-sig wallet
  - [ ] BIP44 single-sig wallet
  - [ ] BIP49 single-sig wallet
