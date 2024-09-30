#[test_only]
module sui_staking::staking_tests{

    use sui::test_scenario::{Self, Scenario};
    use sui_staking::PFP_NFT::{Self, PFPState, NftAdminCap, PFP};
    use sui_staking::code::{Self, CODE};
    use std::ascii::string;
    use sui::random::{Self, Random};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::sui::SUI;
    use sui_staking::staking::{Self, StakingAdminCap, RewardState};
    use sui::clock::{Self};
    use std::debug;

    // MAIN TEST

    #[test]
    fun test_staking() {
        let system = @0x0;
        let owner = @0x1;
        let alice = @0x3;

        let mut scenario_val = test_scenario::begin(owner);
        
        // Owner deploys the contracts
        let scenario = &mut scenario_val;
        {   
            let ctx = test_scenario::ctx(scenario);
            PFP_NFT::init_for_testing(ctx);
            code::init_for_testing( ctx);
            staking::init_for_testing(ctx);
        };

        // Create random object
        test_scenario::next_tx(scenario, system); 
        {
            let ctx = test_scenario::ctx(scenario);
            random::create_for_testing(ctx);
        };

        // Set collection details
        test_scenario::next_tx(scenario, owner); 
        {
            let admin_cap = test_scenario::take_from_sender<NftAdminCap>(scenario);
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

        // Mint CODE tokens
        test_scenario::next_tx(scenario, owner); 
        {
            let mut treasury_cap = test_scenario::take_from_sender<TreasuryCap<CODE>>(scenario);
            let ctx = test_scenario::ctx(scenario);
            let amount = 2_000_000_000_000;
            code::mint(&mut treasury_cap, amount, owner, ctx);
            test_scenario::return_to_sender(scenario, treasury_cap);
        };

        // Set rewards
        test_scenario::next_tx(scenario, owner); 
        { 
            let staking_admin_cap = test_scenario::take_from_sender<StakingAdminCap>(scenario);
            let mut reward_state = test_scenario::take_shared<RewardState>(scenario);
            let duration = 1_000_000;
            let mut reward = test_scenario::take_from_sender<Coin<CODE>>(scenario);
            let amount = 1_000_000_000_000;
            let mut clock = clock::create_for_testing(test_scenario::ctx(scenario));
            let tick = 10_000;
            clock::increment_for_testing(&mut clock, tick);
            let ctx = test_scenario::ctx(scenario);
            
            staking::set_reward(&staking_admin_cap, &mut reward_state, duration, &mut reward, amount, &clock, ctx);

            assert_reward_state_equals(
                &reward_state,
                duration,
                tick + duration,
                tick,
                amount / duration,
                0,
                0,
                amount
            );

            test_scenario::return_to_sender(scenario, staking_admin_cap);
            test_scenario::return_shared(reward_state);
            test_scenario::return_to_sender(scenario, reward);
            clock::destroy_for_testing(clock);
        };


        // Mint 2 NFTs for Alice and store their total value
        let mut alice_total_value = mint_and_get_value(scenario, alice);
        alice_total_value = alice_total_value + mint_and_get_value(scenario, alice);
        debug::print(&alice_total_value);

        let nft_ids = test_scenario::ids_for_address<PFP>( alice);
         
        test_scenario::next_tx(scenario, alice); 
        {
        // public entry fun stake(nft: PFP, reward_state: &mut RewardState, user_registry: &mut UserRegistry, clock: &Clock, ctx: &mut TxContext) {

        };

        test_scenario::end(scenario_val);
    }


    // HELPERS

    fun stake_nft(scenario: &mut Scenario, address: address)  {
        test_scenario::next_tx(scenario, address); 
        {
            // public entry fun stake(nft: PFP, reward_state: &mut RewardState, user_registry: &mut UserRegistry, clock: &Clock, ctx: &mut TxContext) {
            
        };
    }

    // Mint an NFT for address and return its staking value
    fun mint_and_get_value(scenario: &mut test_scenario::Scenario, address: address): u16 {
        let dummy = @0x2;
        test_scenario::next_tx(scenario, address); 
        {
            let random = test_scenario::take_shared<Random>(scenario);
            let mut pfp_state = test_scenario::take_shared<PFPState>(scenario);

            let ctx = test_scenario::ctx(scenario);
            let mut payment = coin::mint_for_testing<SUI>(10_000_000, ctx);

            PFP_NFT::mint(&mut payment, &mut pfp_state, &random, ctx);
            test_scenario::return_shared(pfp_state);
            test_scenario::return_shared(random);
            transfer::public_transfer(payment, dummy);
        };

        // Get the given address's NFTs staking value
        test_scenario::next_tx(scenario, address);
        let address_rarity;
        {
            let pfp_state = test_scenario::take_shared<PFPState>(scenario);
            let nft = test_scenario::take_from_sender<PFP>(scenario);
            address_rarity = PFP_NFT::get_rarity(&nft);
            test_scenario::return_to_sender(scenario, nft);
            test_scenario::return_shared(pfp_state);
        };

        address_rarity + 1
    }
 

    #[test_only]
    public fun assert_reward_state_equals(
        reward_state: &RewardState,
        duration: u64,
        finish_at: u64,
        updated_at: u64,
        reward_rate: u64,
        rewards_total_value: u64,
        rewards_per_share: u64,
        total_rewards: u64
    ) {
        assert!(staking::get_reward_state_duration(reward_state) == duration, 1);
        assert!(staking::get_reward_state_finish_at(reward_state) == finish_at, 2);
        assert!(staking::get_reward_state_updated_at(reward_state) == updated_at, 3);
        assert!(staking::get_reward_state_reward_rate(reward_state) == reward_rate, 4);
        assert!(staking::get_reward_state_staked_value(reward_state) == rewards_total_value, 5);
        assert!(staking::get_reward_state_rewards_per_share(reward_state) == rewards_per_share, 6);
        assert!(staking::get_reward_state_total_rewards(reward_state) == total_rewards, 7);
    }

}