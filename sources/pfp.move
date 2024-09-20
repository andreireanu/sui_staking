module sui_staking::PFP_NFT {
    use sui::coin::{Self, Coin};
    use sui::table::{Self, Table};
    // use std::ascii::String;
    // use std::string::String as String;
    use std::ascii::String;
    // use std::string::{utf8};
    use sui::sui::SUI;
    use sui::url::{Self, Url};
    use sui::random::{Random, new_generator};
    use sui::balance;


    const COMMON: u8 = 1;
    const RARE: u8 = 2;
    const LEGENDARY: u8 = 3;
    const EPIC: u8 = 4;

    const TOTAL_COMMON: u64 = 5000;
    const TOTAL_RARE: u64 = 3000;
    const TOTAL_LEGENDARY: u64 = 1500;
    const TOTAL_EPIC: u64 = 500;
    const TOTAL_NFTS: u64 = 10_000;
    const MINT_COST: u64 = 100_000_000; // 0.1 SUI

    public struct PFP has key, store {
        id: UID,
        name : String,
        rarity: u8,
        img_url : Url,
    }

    public struct PFPState has key {
        id: UID,
        total_minted: u64,
        minted_per_rarity: Table<u8, u64>,
        treasury: sui::balance::Balance<SUI>,
        url_vec: vector<Url>,
        name_vec: vector<String>,
    }

    public struct AdminCap has key {  
        id: UID
    }

    const EInvalidAmount: u64 = 200;
    const EAllNFTsMinted: u64 = 201;
    const ENoRaritiesLeft: u64 = 202;

    fun init(ctx: &mut TxContext) {
        let pfp_state = PFPState {
            id: object::new(ctx),
            total_minted: 0,
            minted_per_rarity: table::new(ctx),
            treasury: balance::zero(),
            url_vec: vector::empty<Url>(),
            name_vec: vector::empty<String>(),
        };
        
        transfer::share_object(pfp_state);

        let admin_cap = AdminCap { id: object::new(ctx) };
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    entry fun set_collection( _ : &AdminCap, pfp_state: &mut PFPState, 
        common_name: String,
        common_url: String, 
        rare_name: String,
        rare_url: String, 
        legendary_name: String,
        legendary_url: String, 
        epic_name: String,
        epic_url: String) 
        {
        if (pfp_state.url_vec.length() == 4) {
            return
        };
        vector::push_back(&mut pfp_state.name_vec, common_name);
        vector::push_back(&mut pfp_state.url_vec, url::new_unsafe(common_url));
        vector::push_back(&mut pfp_state.name_vec, rare_name);
        vector::push_back(&mut pfp_state.url_vec, url::new_unsafe(rare_url));
        vector::push_back(&mut pfp_state.name_vec, legendary_name);
        vector::push_back(&mut pfp_state.url_vec, url::new_unsafe(legendary_url));
        vector::push_back(&mut pfp_state.name_vec, epic_name);
        vector::push_back(&mut pfp_state.url_vec, url::new_unsafe(epic_url));
    }

    entry fun mint(payment: &mut Coin<SUI>, pfp_state: &mut PFPState, random: &Random, ctx: &mut TxContext) {
        let amount = coin::value(payment);
        assert!(amount >= MINT_COST, EInvalidAmount);
        assert!(pfp_state.total_minted < TOTAL_NFTS, EAllNFTsMinted);
        
        let mint_cost_coin = coin::split(payment, MINT_COST, ctx);
        let mint_cost_balance = coin::into_balance(mint_cost_coin);
        balance::join(&mut pfp_state.treasury, mint_cost_balance);

        let rarity = select_rarity(pfp_state, random, ctx);
        let pfp = mint_nft(rarity, pfp_state, ctx);
        transfer::transfer(pfp, tx_context::sender(ctx));
    }

    fun mint_nft(rarity: u8, pfp_state: &mut PFPState, ctx: &mut TxContext): PFP{

        let pfp = PFP {
            id: object::new(ctx),
            name: pfp_state.name_vec[rarity as u64],
            rarity: rarity,
            img_url: pfp_state.url_vec[rarity as u64],
        };

        if (table::contains(&pfp_state.minted_per_rarity, rarity)) {
            let count = table::borrow_mut(&mut pfp_state.minted_per_rarity, rarity);
            *count = *count + 1;
        } else {
            table::add(&mut pfp_state.minted_per_rarity, rarity, 1);
        };
        pfp_state.total_minted = pfp_state.total_minted + 1;
        pfp
    }

    fun select_rarity(pfp_state: &PFPState, random: &Random, ctx: &mut TxContext): u8 {
        let mut available_rarities = vector::empty<u8>();
        
        if (!table::contains(&pfp_state.minted_per_rarity, COMMON) || 
            *table::borrow(&pfp_state.minted_per_rarity, COMMON) < TOTAL_COMMON) {
            vector::push_back(&mut available_rarities, COMMON);
        };
        if (!table::contains(&pfp_state.minted_per_rarity, RARE) || 
            *table::borrow(&pfp_state.minted_per_rarity, RARE) < TOTAL_RARE) {
            vector::push_back(&mut available_rarities, RARE);
        };
        if (!table::contains(&pfp_state.minted_per_rarity, LEGENDARY) || 
            *table::borrow(&pfp_state.minted_per_rarity, LEGENDARY) < TOTAL_LEGENDARY) {
            vector::push_back(&mut available_rarities, LEGENDARY);
        };
        if (!table::contains(&pfp_state.minted_per_rarity, EPIC) || 
            *table::borrow(&pfp_state.minted_per_rarity, EPIC) < TOTAL_EPIC) {
            vector::push_back(&mut available_rarities, EPIC);
        };

        assert!(!vector::is_empty(&available_rarities), ENoRaritiesLeft);

        let mut generator = new_generator(random, ctx);
        let length = vector::length(&available_rarities);
        let random_index = generator.generate_u8_in_range(0, length as u8);
        *vector::borrow(&available_rarities, random_index as u64)
    }

    public fun burn(pfp: PFP) {
        let PFP { id, .. } = pfp;
        id.delete()
    }

    entry fun withdraw(_: &AdminCap, pfp_state: &mut PFPState, amount: u64, ctx: &mut TxContext) {
        assert!(balance::value(&pfp_state.treasury) >= amount, EInvalidAmount);
        let withdrawal_amount = coin::take<SUI>(&mut pfp_state.treasury, amount, ctx);
        transfer::public_transfer(withdrawal_amount, tx_context::sender(ctx));
    }
}