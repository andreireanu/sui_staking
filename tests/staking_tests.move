#[test_only]
module sui_staking::staking_tests{

    use sui::test_scenario::{Self, Scenario};
    use sui_staking::PFP_NFT::{Self, PFPState, NftAdminCap, PFP};
    use sui_staking::code::{Self, CODE};
    use std::ascii::string;
    use sui::random::{Self, Random};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::sui::SUI;
    use sui_staking::staking::{
        Self, 
        StakingAdminCap, 
        RewardState, 
        UserRegistry, 
        UserState};
    use sui::clock::{Self, Clock};
    use std::debug;

    const DIVISION_SAFETY_CONSTANT: u64 = 1;

    // MAIN TEST

    #[test]
    fun test_staking() {
        let system = @0x0;
        let owner = @0x1;
        let alice = @0x2;
        let bob = @0x3;

        let mut scenario_val = test_scenario::begin(owner);
        
        // Owner deploys the contracts
        let scenario = &mut scenario_val;
        let mut clock = clock::create_for_testing(test_scenario::ctx(scenario));
        let tick = 10_000; // we increment the clock by 10 seconds to simplify the calculation 
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

        let duration = 1_000_000;
        let amount = 1_000_000_000_000;

        // Set rewards
        test_scenario::next_tx(scenario, owner); 
        { 
            let staking_admin_cap = test_scenario::take_from_sender<StakingAdminCap>(scenario);
            let mut reward_state = test_scenario::take_shared<RewardState>(scenario);
            let mut reward = test_scenario::take_from_sender<Coin<CODE>>(scenario);
            
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
        };

        // Mint 2 NFTs for Alice and store their values
        let alice_nft_0_value = mint_and_get_value(scenario, alice);
        let alice_nft_1_value = mint_and_get_value(scenario, alice);
        debug::print(&alice_nft_0_value);
        debug::print(&alice_nft_1_value);

        let nft_ids = test_scenario::ids_for_address<PFP>( alice);

        clock::increment_for_testing(&mut clock, tick);
        let mut alice_staked_nfts = vector::empty<ID>();
        let mut total_staked = 0;
        let mut rewards_per_share = 0;

        // Alice stakes the first NFT
        test_scenario::next_tx(scenario, alice); 
        {
            let nft_0 = test_scenario::take_from_address_by_id<PFP>(scenario, alice, nft_ids[0]);
            stake_nft(scenario, alice, nft_0, &clock);
            vector::push_back(&mut alice_staked_nfts, nft_ids[0]);
        };

        // Check Alice state and global state
        test_scenario::next_tx(scenario, alice); 
        {
            let user_registry = test_scenario::take_shared<UserRegistry>(scenario);
            let user_state = staking::get_user_state(&user_registry, alice);

            assert_user_state_equals(
                user_state,
                &alice_staked_nfts, 
                alice_nft_0_value,
                rewards_per_share,
                0
            );

            let reward_state = test_scenario::take_shared<RewardState>(scenario);
            total_staked = total_staked + alice_nft_0_value;

            assert_reward_state_equals(
                &reward_state,
                duration,
                tick + duration,
                tick * 2,
                amount / duration,
                total_staked,
                rewards_per_share,
                amount
            );

            test_scenario::return_shared(user_registry);
            test_scenario::return_shared(reward_state);
        };


        clock::increment_for_testing(&mut clock, tick);

        // Alice stakes the second NFT
        test_scenario::next_tx(scenario, alice); 
        {
            let nft_1 = test_scenario::take_from_address_by_id<PFP>(scenario, alice, nft_ids[1]);
            stake_nft(scenario, alice, nft_1, &clock);
            vector::push_back(&mut alice_staked_nfts, nft_ids[1]);
        };
         
        // Check Alice state and global state
        test_scenario::next_tx(scenario, alice); 
        {
            let user_registry = test_scenario::take_shared<UserRegistry>(scenario);
            let user_state = staking::get_user_state(&user_registry, alice);
            let reward_state = test_scenario::take_shared<RewardState>(scenario);
            
            rewards_per_share = rewards_per_share + 
               tick * DIVISION_SAFETY_CONSTANT * reward_state.get_reward_state_reward_rate() / total_staked;
            total_staked = total_staked + alice_nft_1_value;

            assert_user_state_equals(
                user_state,
                &alice_staked_nfts, 
                alice_nft_0_value + alice_nft_1_value,
                rewards_per_share,
                9_999_999_999 // 1 milionth of the reward is lost in division
            );


            assert_reward_state_equals(
                &reward_state,
                duration,
                tick + duration,
                tick * 3,
                amount / duration,
                total_staked,
                rewards_per_share,
                amount - 9_999_999_999
            );

            test_scenario::return_shared(user_registry);
            test_scenario::return_shared(reward_state);
        };
 
        // Mint 2 NFTs for Bob and store their values
        let bob_nft_0_value = mint_and_get_value(scenario, bob);
        let bob_nft_1_value = mint_and_get_value(scenario, bob);
        debug::print(&bob_nft_0_value);
        debug::print(&bob_nft_1_value);

        let mut bob_staked_nfts = vector::empty<ID>();
        let nft_ids = test_scenario::ids_for_address<PFP>( bob);

        clock::increment_for_testing(&mut clock, tick);

        // Bob stakes the first NFT
        test_scenario::next_tx(scenario, bob); 
        {
            let nft_0 = test_scenario::take_from_address_by_id<PFP>(scenario, bob, nft_ids[0]);
            stake_nft(scenario, bob, nft_0, &clock);
            vector::push_back(&mut bob_staked_nfts, nft_ids[0]);
        };

        // Check Bob state and global state
        test_scenario::next_tx(scenario, bob); 
        {
            let user_registry = test_scenario::take_shared<UserRegistry>(scenario);
            let user_state = staking::get_user_state(&user_registry, bob);
            let reward_state = test_scenario::take_shared<RewardState>(scenario);

            rewards_per_share = rewards_per_share + 
               tick * DIVISION_SAFETY_CONSTANT * reward_state.get_reward_state_reward_rate() / total_staked;
            total_staked = total_staked + bob_nft_0_value;

            assert_user_state_equals(
                user_state,
                &bob_staked_nfts, 
                bob_nft_0_value,
                rewards_per_share,
                0
            );
            
            assert_reward_state_equals(
                &reward_state,
                duration,
                tick + duration,
                tick * 4,
                amount / duration,
                total_staked,
                rewards_per_share,
                amount - 9_999_999_999
            );

            test_scenario::return_shared(user_registry);
            test_scenario::return_shared(reward_state);
        };

        clock::increment_for_testing(&mut clock, tick);

        // Bob stakes the second NFT
        test_scenario::next_tx(scenario, bob); 
        {
            let nft_1 = test_scenario::take_from_address_by_id<PFP>(scenario, bob, nft_ids[1]);
            stake_nft(scenario, bob, nft_1, &clock);
            vector::push_back(&mut bob_staked_nfts, nft_ids[1]);
        };

        // Check Bob state and global state
        test_scenario::next_tx(scenario, bob); 
        {
            let user_registry = test_scenario::take_shared<UserRegistry>(scenario);
            let user_state = staking::get_user_state(&user_registry, bob);
            let reward_state = test_scenario::take_shared<RewardState>(scenario);

            rewards_per_share = rewards_per_share + 
               tick * DIVISION_SAFETY_CONSTANT * reward_state.get_reward_state_reward_rate() / total_staked;
            total_staked = total_staked + bob_nft_1_value;

            assert_user_state_equals(
                user_state,
                &bob_staked_nfts, 
                bob_nft_0_value + bob_nft_1_value,
                rewards_per_share,
                2_222_222_222
            );
            
            assert_reward_state_equals(
                &reward_state,
                duration,
                tick + duration,
                tick * 5,
                amount / duration,
                total_staked,
                rewards_per_share,
                amount - 9_999_999_999 - 2_222_222_222
            );

            test_scenario::return_shared(user_registry);
            test_scenario::return_shared(reward_state);
        };

        clock::increment_for_testing(&mut clock, tick);

        // Alice claims rewards
        test_scenario::next_tx(scenario, alice); 
        {
            let mut reward_state = test_scenario::take_shared<RewardState>(scenario);
            let mut user_registry = test_scenario::take_shared<UserRegistry>(scenario);
            let ctx = test_scenario::ctx(scenario);

            staking::claim_rewards_for_testing(&mut reward_state, &mut user_registry, &clock, ctx);

            test_scenario::return_shared(reward_state);
            test_scenario::return_shared(user_registry);
        };
        // Check Alice state and global state
        test_scenario::next_tx(scenario, alice); 
        {
            let user_registry = test_scenario::take_shared<UserRegistry>(scenario);
            let user_state = staking::get_user_state(&user_registry, alice);
            let reward_state = test_scenario::take_shared<RewardState>(scenario);

            rewards_per_share = rewards_per_share + 
               tick * DIVISION_SAFETY_CONSTANT * reward_state.get_reward_state_reward_rate() / total_staked;

            assert_user_state_equals(
                user_state,
                &alice_staked_nfts, 
                alice_nft_0_value + alice_nft_1_value,
                rewards_per_share,
                0
            );

            assert_reward_state_equals(
                &reward_state,
                duration,
                tick + duration,
                tick * 6,
                amount / duration,
                total_staked,
                rewards_per_share,
                amount - 9_999_999_999 - 2_222_222_222 - 23_611_111_104
            );

            test_scenario::return_shared(reward_state);
            test_scenario::return_shared(user_registry);

        };
 
        clock::increment_for_testing(&mut clock, tick);

        // Alice unstakes the first NFT
        test_scenario::next_tx(scenario, alice); 
        {
            let mut user_registry = test_scenario::take_shared<UserRegistry>(scenario);
            let mut reward_state = test_scenario::take_shared<RewardState>(scenario);
            let ctx = test_scenario::ctx(scenario);
            staking::unstake_for_testing(alice_staked_nfts[0],  &mut reward_state, &mut user_registry, &clock, ctx);
            vector::remove(&mut alice_staked_nfts, 0);

            test_scenario::return_shared(reward_state);
            test_scenario::return_shared(user_registry);
        };
 
        // Check Alice state and global state
        test_scenario::next_tx(scenario, alice); 
        {
            let user_registry = test_scenario::take_shared<UserRegistry>(scenario);
            let user_state = staking::get_user_state(&user_registry, alice);
            let reward_state = test_scenario::take_shared<RewardState>(scenario);

            rewards_per_share = rewards_per_share + 
               tick * DIVISION_SAFETY_CONSTANT * reward_state.get_reward_state_reward_rate()   / total_staked;

            total_staked = total_staked - alice_nft_0_value; 
             
            assert_user_state_equals(
                user_state,
                &alice_staked_nfts, 
                alice_nft_1_value,
                rewards_per_share,
                5_833_333_331
            );

            assert_reward_state_equals(
                &reward_state,
                duration,
                tick + duration,
                tick * 7,
                amount / duration,
                total_staked,
                rewards_per_share,
                amount - 9_999_999_999 - 2_222_222_222 - 23_611_111_104 - 5_833_333_331
            );

            test_scenario::return_shared(reward_state);
            test_scenario::return_shared(user_registry);

        };

        clock::increment_for_testing(&mut clock, tick);

        // Alice claims rewards
        test_scenario::next_tx(scenario, alice); 
        {
            let mut reward_state = test_scenario::take_shared<RewardState>(scenario);
            let mut user_registry = test_scenario::take_shared<UserRegistry>(scenario);
            let ctx = test_scenario::ctx(scenario);

            staking::claim_rewards_for_testing(&mut reward_state, &mut user_registry, &clock, ctx);

            test_scenario::return_shared(reward_state);
            test_scenario::return_shared(user_registry);
        };
        // Check Alice state and global state
        test_scenario::next_tx(scenario, alice); 
        {
            let user_registry = test_scenario::take_shared<UserRegistry>(scenario);
            let user_state = staking::get_user_state(&user_registry, alice);
            let reward_state = test_scenario::take_shared<RewardState>(scenario);

            rewards_per_share = rewards_per_share + 
               tick * DIVISION_SAFETY_CONSTANT * reward_state.get_reward_state_reward_rate() / total_staked;

            assert_user_state_equals(
                user_state,
                &alice_staked_nfts, 
                alice_nft_1_value,
                rewards_per_share,
                0
            );

            assert_reward_state_equals(
                &reward_state,
                duration,
                tick + duration,
                tick * 8,
                amount / duration,
                total_staked,
                rewards_per_share,
                amount - 9_999_999_999 - 2_222_222_222 - 23_611_111_104 - 10_277_777_775
            );

            test_scenario::return_shared(reward_state);
            test_scenario::return_shared(user_registry);

        };

        // Bob claims rewards
        test_scenario::next_tx(scenario, bob); 
        {
            let mut reward_state = test_scenario::take_shared<RewardState>(scenario);
            let mut user_registry = test_scenario::take_shared<UserRegistry>(scenario);
            let ctx = test_scenario::ctx(scenario);

            staking::claim_rewards_for_testing(&mut reward_state, &mut user_registry, &clock, ctx);

            test_scenario::return_shared(reward_state);
            test_scenario::return_shared(user_registry);
        };
        // Check Bob state and global state
        test_scenario::next_tx(scenario, bob); 
        {
            let user_registry = test_scenario::take_shared<UserRegistry>(scenario);
            let user_state = staking::get_user_state(&user_registry, bob);
            let reward_state = test_scenario::take_shared<RewardState>(scenario);

            assert_user_state_equals(
                user_state,
                &bob_staked_nfts, 
                bob_nft_0_value + bob_nft_1_value,
                rewards_per_share,
                0
            );

            assert_reward_state_equals(
                &reward_state,
                duration,
                tick + duration,
                tick * 8,
                amount / duration,
                total_staked,
                rewards_per_share,
                amount - 9_999_999_999 - 2_222_222_222 - 23_611_111_104 - 10_277_777_775 - 13_888_888_885
            );

            test_scenario::return_shared(reward_state);
            test_scenario::return_shared(user_registry);

        };
 
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }


    // HELPERS

    fun stake_nft(scenario: &mut Scenario, address: address, nft: PFP, clock: &Clock) {  
        test_scenario::next_tx(scenario, address); 
        {
            let mut reward_state = test_scenario::take_shared<RewardState>(scenario);
            let mut user_registry = test_scenario::take_shared<UserRegistry>(scenario);
            let ctx = test_scenario::ctx(scenario);

            staking::stake_for_testing(nft, &mut reward_state, &mut user_registry, clock, ctx);

            test_scenario::return_shared(reward_state);
            test_scenario::return_shared(user_registry);
        };
    }

    // Mint an NFT for address and return its staking value
    fun mint_and_get_value(scenario: &mut test_scenario::Scenario, address: address): u64 {
        let dummy = @0x999999;
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
        total_staked: u64,
        rewards_per_share: u64,
        total_rewards: u64
    ) {
        assert!(staking::get_reward_state_duration(reward_state) == duration, 1);
        assert!(staking::get_reward_state_finish_at(reward_state) == finish_at, 2);
        assert!(staking::get_reward_state_updated_at(reward_state) == updated_at, 3);
        assert!(staking::get_reward_state_reward_rate(reward_state) == reward_rate, 4);
        assert!(staking::get_reward_state_staked_value(reward_state) == total_staked, 5);
        assert!(staking::get_reward_state_rewards_per_share(reward_state) == rewards_per_share, 6);
        assert!(staking::get_reward_state_total_rewards(reward_state) == total_rewards, 7);
    }

    public fun assert_user_state_equals(
        state: &UserState,
        staked_nfts: &vector<ID>,
        staked_value: u64,
        last_rewards_per_share: u64,
        pending_rewards: u64
    ) {
        assert_vector_has_ids(staking::get_user_state_staked_nfts(state), staked_nfts);
        assert!(staking::get_user_state_staked_value(state) == staked_value, 3);
        assert!(staking::get_user_state_last_rewards_per_share(state) == last_rewards_per_share, 4); 
        assert!(staking::get_user_state_pending_rewards(state) == pending_rewards, 5);
    }

    public fun assert_vector_has_ids(v: &vector<PFP>, ids: &vector<ID>) {
        assert!(vector::length(v) == vector::length(ids), 1);
        let mut i = 0;
        while (i < vector::length(v)) {
            assert!(vector::borrow(v, i).get_id() == vector::borrow(ids, i), 2);
            i = i + 1;
        }
    }

}