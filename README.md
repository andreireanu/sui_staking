#### PUBLISH:
```bash
sui client publish --gas-budget 100000000
```

#### CALL SET_COLLECTION FUNCTION (change package name and minter cap after publishing):
```bash
sui client call \
--package 0xc918fe5cdecd33457b3217496a521b1b431fa89d6ce88ae251780b25e617bb01 \
--module PFP_NFT \
--function set_collection \
--args "0x5f20cd8bfb46b991359715d227e791aa686c84b557dbee2347190289405e5247" \
"0x3ef48f97451e228630134f3d53d249220e0e8e1ecb92a81ba1304474ed31f37c" \
"Common" \
"https://i.imgur.com/TYekL74.png" \
"Rare" \
"https://i.imgur.com/9Lu930k.png" \
"Legendary" \
"https://i.imgur.com/C965eRh.png" \
"Epic" \
"https://i.imgur.com/NkSyJjT.png" \
--gas-budget 100000000
 
```

#### CALL MINT FUNCTION (change package name and minter cap after publishing):
```bash
sui client call \
--package 0xc918fe5cdecd33457b3217496a521b1b431fa89d6ce88ae251780b25e617bb01 \
--module PFP_NFT \
--function mint \
--args "0xb0b9ed0e943344e82b0deeba7e1a8d3de728a3084ee8f1aed91dc4c094744eb6" \
"0x3ef48f97451e228630134f3d53d249220e0e8e1ecb92a81ba1304474ed31f37c" \
"0x8"
--gas-budget 100000000
 
```


Collection image:   "https://imgur.com/nWGBDqQ" \
Common url:         "https://i.imgur.com/TYekL74.png" \
Rare url:           "https://i.imgur.com/9Lu930k.png" \
Legendary url:      "https://i.imgur.com/C965eRh.png" \
Epic url:           "https://i.imgur.com/NkSyJjT.png"


 