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
--package 0x11c28eef71a26d572c09d67baf01252b8946d41d61b76701172416cb2cbe5089 \
--module PFP_NFT \
--function set_collection \
--args "0xb12e8d1e1a178f7055e60a8f100219419aaaedd3201ec081c7be525ed194b6a3" \
"0x2c4793240066f5b9f9b2dc07a8024329579b374a8a3361b2120221e30dba3ef0" \
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
--package 0x11c28eef71a26d572c09d67baf01252b8946d41d61b76701172416cb2cbe5089 \
--module PFP_NFT \
--function mint \
--args "0x8179bdabfe31593f77d9132d4d3ab39ca179e7d07bf1e0778e187f5078d9945b" \
"0x2c4793240066f5b9f9b2dc07a8024329579b374a8a3361b2120221e30dba3ef0" \
"0x8" \
--gas-budget 100000000
 
```

 
Collection on chain: https://suiscan.xyz/testnet/collection/0x97d7b904a8eae1bab03d5ce6e2f0c7ed42840d5d6c80639a52f2e4a38870197f::PFP_NFT::PFP/items 
Collection image:   "https://imgur.com/nWGBDqQ" \
Common url:         "https://i.imgur.com/TYekL74.png" \
Rare url:           "https://i.imgur.com/9Lu930k.png" \
Legendary url:      "https://i.imgur.com/C965eRh.png" \
Epic url:           "https://i.imgur.com/NkSyJjT.png"


 