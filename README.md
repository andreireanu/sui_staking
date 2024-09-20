#### PUBLISH:
```bash
sui client publish --gas-budget 100000000
```

#### CALL MINT_NFT FUNCTION (change package name and minter cap after publishing):
```bash
sui client call \
--package 0x9c674a8276d60aa30d8ef81b09b7e967d5ad1527ee65aad4165fe6fc3d98ea14 \
--module PFP_NFT \
--function mint \
--args "0xb0b9ed0e943344e82b0deeba7e1a8d3de728a3084ee8f1aed91dc4c094744eb6" \
"0x303ce76d2e02f26a61cb7e9a69e56db3d81c62fe7e270403de955ff127c001c7" \
"0x0000000000000000000000000000000000000000000000000000000000000008" \
--gas-budget 100000000
 
```

Collection image: https://imgur.com/nWGBDqQ 
Common url:         "https://i.imgur.com/TYekL74.png"
Rare url:           "https://i.imgur.com/9Lu930k.png"
Legendary url:      "https://i.imgur.com/C965eRh.png"
Epic url:           "https://i.imgur.com/NkSyJjT.png"


 