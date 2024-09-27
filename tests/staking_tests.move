#[test_only]
module sui_staking::staking_tests{

    use sui::test_scenario;
    use sui_staking::PFP_NFT::{Self, PFPState, AdminCap, PFP};
    use std::ascii::string;
    use sui::random::{Self, Random};
    use sui::coin::{Self};
    use sui::sui::SUI;
    use std::debug;
 
    #[test]
    fun test_staking() {
        let system = @0x0;
        let owner = @0x1;
        let dummy = @0x2;
        let alice = @0x3;

        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        {   
            // Owner deploys the contracts
            let ctx = test_scenario::ctx(scenario);
            PFP_NFT::init_for_testing(ctx);
        };

        test_scenario::next_tx(scenario, system); 
        {
            let ctx = test_scenario::ctx(scenario);
            random::create_for_testing(ctx);
        };

        test_scenario::next_tx(scenario, owner); 
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut pfp_state = test_scenario::take_shared<PFPState>(scenario);

            let common_name = string(b"Common");
            let common_url = string(b"https://i.imgur.com/TYekL74.png");
            let rare_name = string(b"Rare");
            let rare_url = string(b"https://i.imgur.com/9Lu930k.png");
            let legendary_name = string(b"Legendary");
            let legendary_url = string(b"https://i.imgur.com/NkSyJjT.png");
            let epic_name = string(b"Epic");
            let epic_url = string(b"https://i.imgur.com/C965eRh.png");

            PFP_NFT::set_collection(
                &admin_cap,
                &mut pfp_state,
                common_name,
                common_url,
                rare_name,
                rare_url,
                legendary_name,
                legendary_url,
                epic_name,
                epic_url
            );
 
            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(pfp_state);
        };

        test_scenario::next_tx(scenario, alice); 
        {
            let random = test_scenario::take_shared<Random>(scenario);
            let mut pfp_state = test_scenario::take_shared<PFPState>(scenario);

            let ctx = test_scenario::ctx(scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx);

            PFP_NFT::mint( &mut payment, &mut pfp_state, &random, ctx);
            
            let minted_per_rarity = pfp_state.get_minted_per_rarity();
            debug::print(&minted_per_rarity);

            let alice_nft = test_scenario::take_from_sender<PFP>(scenario);
            let alice_rarity = PFP_NFT::get_rarity(&alice_nft);
            debug::print(&alice_rarity);

            // test_scenario::return_to_sender(scenario, alice_nft);
            transfer::public_transfer(alice_nft, alice);
            test_scenario::return_shared(pfp_state);
            test_scenario::return_shared(random);
            transfer::public_transfer(payment, dummy);
        };
        test_scenario::end(scenario_val);
    }
    
}