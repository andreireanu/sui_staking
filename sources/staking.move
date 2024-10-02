module sui_staking::staking {

    use sui::balance::{Self, Balance};
    use sui_staking::PFP_NFT::{Self, PFP};
    use sui_staking::code::CODE;
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};
    use sui::table::{Self, Table};
    use std::debug;

    const DIVISION_SAFETY_CONSTANT: u64 = 1;

    /// Every staked NFT has a reward multiplier according to its rarity:
    /// Common: 1
    /// Rare: 2
    /// Epic: 3
    /// Legendary: 4
    /// 

    public struct RewardState has key {
        id: UID,
        duration: u64, // Set by the Owner: Duration of rewards to be paid out (in seconds)
        finish_at: u64, // Timestamp of when the rewards finish
        updated_at: u64, // Minimum of last updated time and reward finish time
        reward_rate: u64, // Reward to be paid out per second: determined by the duration & amount of rewards
        staked_value : u64, // Total value of NFTs staked
        rewards_per_share: u64, // Rewards per share
        total_rewards: Balance<CODE>, // Total rewards to be distributed
    }

    public struct UserState has store, key {
        id: UID,
        staked_nfts: vector<PFP>, // Mapping that keeps track of users' staked NFTs
        staked_value: u64,
        last_rewards_per_share: u64,
        pendingRewards: Balance<CODE>,
    }

    public struct UserRegistry has key {
        id: UID,
        users: Table<address, UserState>,
    }

    public struct StakingAdminCap has key {  
        id: UID
    }

    const ERewardDurationNotExpired: u64 = 100;
    // const EZeroreward_rate: u64 = 101;
    // const EZeroAmount: u64 = 102;
    // const ELowRewardsTreasuryBalance: u64 = 103;
    // const ERequestedAmountExceedsStaked: u64 = 104;
    // const ENoRewardsToClaim: u64 = 105;
    // const ENoStakedTokens: u64 = 106;
    // const ENoPriorTokenStake: u64 = 107;
    const EInvalidTimestamp: u64 = 108;

    fun init (ctx: &mut TxContext) {
        transfer::share_object(RewardState{
            id: object::new(ctx),
            duration: 0,  
            finish_at: 0,  
            updated_at: 0,   
            reward_rate: 0,   
            staked_value: 0,  
            rewards_per_share: 0,  
            total_rewards: balance::zero<CODE>()  
        });

        transfer::share_object(UserRegistry{
            id: object::new(ctx),
            users: table::new(ctx)
        });

        transfer::transfer(StakingAdminCap {id: object::new(ctx)}, tx_context::sender(ctx));
    }

    public entry fun set_reward(_: &StakingAdminCap, reward_state: &mut RewardState, duration: u64, reward: &mut Coin<CODE>, amount: u64, clock: &Clock, ctx: &mut TxContext) {
        let timestamp = clock::timestamp_ms(clock);
        assert!(reward_state.finish_at < timestamp, ERewardDurationNotExpired);
        reward_state.duration = duration;
        reward_state.reward_rate = amount / reward_state.duration;
        let split_amount = coin::split(reward, amount, ctx);
        let balance = coin::into_balance(split_amount);
        balance::join(&mut reward_state.total_rewards, balance);
        reward_state.updated_at = timestamp;
        reward_state.finish_at = timestamp + reward_state.duration;
    }

    public entry fun stake(nft: PFP, reward_state: &mut RewardState, user_registry: &mut UserRegistry, clock: &Clock, ctx: &mut TxContext) {
        let nft_rarity = PFP_NFT::get_rarity(&nft) as u64;
        update_global_state_general(reward_state, clock);
        reward_state.staked_value = reward_state.staked_value + nft_rarity + 1;
        update_user_state_general_on_stake(nft, reward_state, user_registry, ctx);
    }  

    public entry fun claim_rewards(reward_state: &mut RewardState, user_registry: &mut UserRegistry, ctx: &mut TxContext) {
        let caller = tx_context::sender(ctx);
        let user_state = user_registry.users.borrow_mut(caller);
        let current_rewards = (reward_state.rewards_per_share - user_state.last_rewards_per_share) * user_state.staked_value / reward_state.staked_value;
        user_state.last_rewards_per_share = reward_state.rewards_per_share;
        let pendingRewards = user_state.pendingRewards.value() + current_rewards;
        let total_rewards_coin = coin::take<CODE>(&mut reward_state.total_rewards, pendingRewards, ctx);
        transfer::public_transfer(total_rewards_coin, tx_context::sender(ctx));
    } 

    fun update_global_state_general(reward_state: &mut RewardState, clock: &Clock) {
        let timestamp = clock::timestamp_ms(clock);
        assert!(timestamp > reward_state.updated_at, EInvalidTimestamp);
        if (reward_state.staked_value > 0) {
            reward_state.rewards_per_share = reward_state.rewards_per_share + (timestamp - reward_state.updated_at) * DIVISION_SAFETY_CONSTANT * reward_state.reward_rate / reward_state.staked_value;
        };
        reward_state.updated_at = timestamp;
    }
    
    fun update_user_state_general_on_stake(nft: PFP, reward_state: &mut RewardState, user_registry: &mut UserRegistry, ctx: &mut TxContext) {
        let caller = tx_context::sender(ctx);
        let nft_rarity = PFP_NFT::get_rarity(&nft) as u64;
        if (!table::contains(&user_registry.users, caller)) {
            let userState = UserState {
                id: object::new(ctx),
                staked_nfts: vector::singleton(nft),
                staked_value: nft_rarity + 1,
                last_rewards_per_share: reward_state.rewards_per_share,
                pendingRewards: balance::zero<CODE>()
            }; 
            table::add(&mut user_registry.users, caller, userState);
        } else {
            let user_state = user_registry.users.borrow_mut(caller);
            vector::push_back(&mut user_state.staked_nfts, nft);
            let rewards_to_add = reward_state.rewards_per_share * user_state.staked_value / DIVISION_SAFETY_CONSTANT;
            let rewards_to_add_from_storage = balance::split(&mut reward_state.total_rewards, rewards_to_add);
            balance::join(&mut user_state.pendingRewards , rewards_to_add_from_storage );
            user_state.last_rewards_per_share = reward_state.rewards_per_share;
            user_state.staked_value = user_state.staked_value + nft_rarity + 1;

        }
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }

    #[test_only]
    public fun get_reward_state_duration(reward_state: &RewardState): u64 {
        reward_state.duration
    }

        #[test_only]
    public fun get_reward_state_finish_at(reward_state: &RewardState): u64 {
        reward_state.finish_at
    }

    #[test_only]
    public fun get_reward_state_updated_at(reward_state: &RewardState): u64 {
        reward_state.updated_at
    }

    #[test_only]
    public fun get_reward_state_reward_rate(reward_state: &RewardState): u64 {
        reward_state.reward_rate
    }

    #[test_only]
    public fun get_reward_state_staked_value(reward_state: &RewardState): u64 {
        reward_state.staked_value
    }

    #[test_only]
    public fun get_reward_state_rewards_per_share(reward_state: &RewardState): u64 {
        reward_state.rewards_per_share
    }

    #[test_only]
    public fun get_reward_state_total_rewards(reward_state: &RewardState): u64 {
        reward_state.total_rewards.value()
    }

    #[test_only]
    public fun stake_for_testing(nft: PFP, reward_state: &mut RewardState, user_registry: &mut UserRegistry, clock: &Clock, ctx: &mut TxContext) {
        stake(nft, reward_state, user_registry, clock, ctx);
    }

    #[test_only]
    public fun get_user_state_staked_nfts(state: &UserState): &vector<PFP> {
        &state.staked_nfts
    }

    #[test_only]
    public fun get_user_state_staked_value(state: &UserState): u64 {
        state.staked_value
    }

    #[test_only]
    public fun get_user_state_last_rewards_per_share(state: &UserState): u64 {
        state.last_rewards_per_share
    }

    #[test_only]
    public fun get_user_state_pending_rewards(state: &UserState): u64 {
        state.pendingRewards.value()
    }

    #[test_only]
    public fun get_user_state(user_registry: &UserRegistry, address: address): &UserState {
        user_registry.users.borrow(address)
    }
}