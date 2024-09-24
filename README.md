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
--package 0x7b31e67e04c6bd9298d548ccc07cb34888e84f29c057e9b18f665be6c39c5de0 \
--module PFP_NFT \
--function set_collection \
--args "0x08ce3852142e00323d9a84f994730ad149721eef0a7b6beb7cdb82411a503186" \
"0x2f745a7f24f747a5abd569535e1fd97a6babbbe2eaed8135a54995f14aebf87b" \
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
--package 0x7b31e67e04c6bd9298d548ccc07cb34888e84f29c057e9b18f665be6c39c5de0 \
--module PFP_NFT \
--function mint \
--args "0xa26658d8ca582d78bfda1a9866cf296d9d81a0662f8de1a8875c0b68140180f9" \
"0x2f745a7f24f747a5abd569535e1fd97a6babbbe2eaed8135a54995f14aebf87b" \
"0x8" \
--gas-budget 100000000
 
```


#### CALL WITHDRAW FUNCTION (change package name and minter cap after publishing):
```bash
sui client call \
--package 0x549acd265bc387b8331f07d2e0e392c969397643ce73213080757e207ec2c885 \
--module PFP_NFT \
--function withdraw \
--args "0xb0b9ed0e943344e82b0deeba7e1a8d3de728a3084ee8f1aed91dc4c094744eb6" \
"0x74cfc123cd455ce03c368a24ec2662450ea98dfd22fdb55d5e801e4c5ef78eef" \
"0x8" \
--gas-budget 100000000
 
```

Collection image:   "https://imgur.com/nWGBDqQ" \
Common url:         "https://i.imgur.com/TYekL74.png" \
Rare url:           "https://i.imgur.com/9Lu930k.png" \
Legendary url:      "https://i.imgur.com/C965eRh.png" \
Epic url:           "https://i.imgur.com/NkSyJjT.png"


 