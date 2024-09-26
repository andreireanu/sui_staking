#[test_only]
module sui_staking::staking_tests{

    use sui::test_scenario;
    use sui_staking::PFP_NFT::{Self, PFPState, AdminCap};
    use sui::url;
    use std::ascii::string;
    use sui::random::{Self, Random};
    use sui::coin::{Self};
    use sui::sui::SUI;
    use std::debug;

    #[test]
    fun test_set_collection() {
        let owner = @0x1;

        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        {   
            // Owner deploys the contracts
            let ctx = test_scenario::ctx(scenario);
            PFP_NFT::init_for_testing(ctx);
        };
        test_scenario::next_tx(scenario, owner); 
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut pfp_state = test_scenario::take_shared<PFPState>(scenario);

            // Define test data for names and URLs
            let common_name = string(b"Common");
            let common_url = string(b"https://i.imgur.com/TYekL74.png");
            let rare_name = string(b"Rare");
            let rare_url = string(b"https://i.imgur.com/9Lu930k.png");
            let legendary_name = string(b"Legendary");
            let legendary_url = string(b"https://i.imgur.com/NkSyJjT.png");
            let epic_name = string(b"Epic");
            let epic_url = string(b"https://i.imgur.com/C965eRh.png");

            // Call the set_collection function
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

            let name_vec = PFP_NFT::get_name_vec(&pfp_state);
            let url_vec = PFP_NFT::get_url_vec(&pfp_state);

            assert!(vector::length(name_vec) == 4, 0);
            assert!(vector::length(url_vec) == 4, 1);

            assert!(vector::borrow(name_vec, 0) == &string(b"Common"), 2);
            assert!(vector::borrow(url_vec, 0) == url::new_unsafe(string(b"https://i.imgur.com/TYekL74.png")), 3);

            assert!(vector::borrow(name_vec, 1) == &string(b"Rare"), 4);
            assert!(vector::borrow(url_vec, 1) == url::new_unsafe(string(b"https://i.imgur.com/9Lu930k.png")), 5);

            assert!(vector::borrow(name_vec, 2) == &string(b"Legendary"), 6);
            assert!(vector::borrow(url_vec, 2) == url::new_unsafe(string(b"https://i.imgur.com/NkSyJjT.png")), 7);

            assert!(vector::borrow(name_vec, 3) == &string(b"Epic"), 8);
            assert!(vector::borrow(url_vec, 3) == url::new_unsafe(string(b"https://i.imgur.com/C965eRh.png")), 9);

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_shared(pfp_state);
        };
        test_scenario::end(scenario_val);
    }

 
    #[test]
    fun test_minting() {
        let system = @0x0;
        let owner = @0x1;
        let dummy = @0x2;

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

        test_scenario::next_tx(scenario, owner); 
        {
            let random = test_scenario::take_shared<Random>(scenario);
            let mut pfp_state = test_scenario::take_shared<PFPState>(scenario);

            let ctx = test_scenario::ctx(scenario);
            let mut payment = coin::mint_for_testing<SUI>(1_000_000_000, ctx);

            let mut i = 0;
            while (i < 10 ) {
                PFP_NFT::mint( &mut payment, &mut pfp_state, &random, ctx);
                i = i + 1;
            };

            assert!(pfp_state.get_total_minted() == 10, 0);
            
            let minted_per_rarity = pfp_state.get_minted_per_rarity();
            debug::print(&minted_per_rarity);
            assert!(vector::borrow(&minted_per_rarity, 0) == 4, 1);
            assert!(vector::borrow(&minted_per_rarity, 1) == 3, 2);
            assert!(vector::borrow(&minted_per_rarity, 2) == 2, 3);
            assert!(vector::borrow(&minted_per_rarity, 3) == 1, 4);
            
            test_scenario::return_shared(pfp_state);
            test_scenario::return_shared(random);
            transfer::public_transfer(payment, dummy);


        };
        test_scenario::end(scenario_val);
    }
    
}