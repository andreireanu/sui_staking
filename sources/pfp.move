module sui_staking::PFP_NFT {
    use sui::coin::{Self, Coin};
    use std::ascii::String;
    use sui::sui::SUI;
    use sui::url::{Self, Url};
    use sui::random::{Random, new_generator};
    use sui::balance;

    const TOTAL_COMMON: u16 = 4;
    const TOTAL_RARE: u16 = 3;
    const TOTAL_LEGENDARY: u16 = 2;
    const TOTAL_EPIC: u16 = 1;
    const MINT_COST: u64 = 100_000_000; // 0.1 SUI

    public struct PFP has key, store {
        id: UID,
        name : String,
        rarity: u16,
        img_url : Url,
    }

    public struct PFPState has key {
        id: UID,
        total_minted: u16,
        minted_per_rarity: vector<u16>,
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
    const EInvalidCollection: u64 = 203;

    fun init(ctx: &mut TxContext) {
        let pfp_state = PFPState {
            id: object::new(ctx),
            total_minted: 0,
            minted_per_rarity: vector[0, 0, 0, 0],
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
        assert!(pfp_state.total_minted < TOTAL_COMMON + TOTAL_RARE + TOTAL_EPIC + TOTAL_LEGENDARY, EAllNFTsMinted);
        assert!(pfp_state.url_vec.length() == 4, EInvalidCollection);
        
        let mint_cost_coin = coin::split(payment, MINT_COST, ctx);
        let mint_cost_balance = coin::into_balance(mint_cost_coin);
        balance::join(&mut pfp_state.treasury, mint_cost_balance);

        let rarity = select_rarity(pfp_state, random, ctx);
        let pfp = mint_nft(rarity, pfp_state, ctx);
        transfer::transfer(pfp, tx_context::sender(ctx));
    }

    fun mint_nft(rarity: u64, pfp_state: &mut PFPState, ctx: &mut TxContext): PFP{

        let pfp = PFP {
            id: object::new(ctx),
            name: pfp_state.name_vec[rarity as u64],
            rarity: rarity as u16,
            img_url: pfp_state.url_vec[rarity as u64],
        };

        let count = vector::borrow_mut(&mut pfp_state.minted_per_rarity, rarity);
        *count = *count + 1;
        pfp_state.total_minted = pfp_state.total_minted + 1;
        pfp
    }

    fun select_rarity(pfp_state: &PFPState, random: &Random, ctx: &mut TxContext): u64 {
            
        let left_common = TOTAL_COMMON - pfp_state.minted_per_rarity[0] ;
        let left_rare = TOTAL_RARE - pfp_state.minted_per_rarity[1] ;
        let left_legendary = TOTAL_LEGENDARY- pfp_state.minted_per_rarity[3] ;
        let left_epic = TOTAL_EPIC - pfp_state.minted_per_rarity[2] ;
        
        let total_left = left_common + left_rare + left_legendary + left_epic;

        assert!(total_left == 0, ENoRaritiesLeft);

        let mut generator = new_generator(random, ctx);
        let random_index = generator.generate_u16_in_range(0, total_left);

        if (random_index < left_common) {
            return 0
        } else if (random_index < left_common + left_rare) {
            return 1
        } else if (random_index < left_common + left_rare + left_epic) {
            return 2
        } else {
            return 3
        }
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