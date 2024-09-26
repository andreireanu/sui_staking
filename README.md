#### SPLIT COIN:
```bash
sui client pay-sui --input-coins 0x02ea29302ccb57949db982a42b25aac7734dfd8ce39c21a3b6f8539047872047 --recipients 0xe2623b169befe8f6e24e317e4d3afc145ccd4ab7237b9311a02ceb863043e98a --amounts 2000000000 --gas-budget 100000000
 ```

#### PUBLISH:
```bash
sui client publish --gas-budget 100000000
```

#### CALL SET_COLLECTION FUNCTION (change package name and minter cap after publishing):
```bash
sui client call \
--package 0x97d7b904a8eae1bab03d5ce6e2f0c7ed42840d5d6c80639a52f2e4a38870197f \
--module PFP_NFT \
--function set_collection \
--args "0x579705cd6df1438e837627e7eff9386c367dc5ba58b793e5c8e85471a5765bf5" \
"0xf07b1359e7ee30e511de2e57a12c5f43e4b14fb24cf39a0379590303cf8683c2" \
"Common" \
"https://i.imgur.com/TYekL74.png" \
"Rare" \
"https://i.imgur.com/9Lu930k.png" \
"Legendary" \
"https://i.imgur.com/NkSyJjT.png" \
"Epic" \
"https://i.imgur.com/C965eRh.png" \
--gas-budget 100000000
 
```

#### CALL MINT FUNCTION (change package name and minter cap after publishing):
```bash
sui client call \
--package 0x97d7b904a8eae1bab03d5ce6e2f0c7ed42840d5d6c80639a52f2e4a38870197f \
--module PFP_NFT \
--function mint \
--args "0xa26658d8ca582d78bfda1a9866cf296d9d81a0662f8de1a8875c0b68140180f9" \
"0xf07b1359e7ee30e511de2e57a12c5f43e4b14fb24cf39a0379590303cf8683c2" \
"0x8" \
--gas-budget 100000000
 
```

 
Collection on chain: https://suiscan.xyz/testnet/collection/0x97d7b904a8eae1bab03d5ce6e2f0c7ed42840d5d6c80639a52f2e4a38870197f::PFP_NFT::PFP/items 
Collection image:   "https://imgur.com/nWGBDqQ" \
Common url:         "https://i.imgur.com/TYekL74.png" \
Rare url:           "https://i.imgur.com/9Lu930k.png" \
Legendary url:      "https://i.imgur.com/C965eRh.png" \
Epic url:           "https://i.imgur.com/NkSyJjT.png"


 