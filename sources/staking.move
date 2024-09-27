module sui_staking::staking {

    use sui::balance::{Self, Balance};
    use sui_staking::PFP_NFT::{Self, PFP};
    use sui_staking::code::CODE;
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};
    use sui::table::{Self, Table};

    const DIVISION_SAFETY_CONSTANT: u64 = 1_000_000_000;

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
        rewards_total_parts : u64, // Total parts of rewards to be distributed
        rewards_per_share: u64, // Rewards per share
        total_rewards: Balance<CODE>, // Total rewards to be distributed
    }

    public struct UserState has store, key {
        id: UID,
        address: address,
        stakedNfts: vector<PFP>, // Mapping that keeps track of users' staked NFTs
        stakedParts: u64,
        last_rewards_per_share: u64,
        pendingRewards: Balance<CODE>,
    }

    public struct UserRegistry has key {
        id: UID,
        users: Table<address, UserState>,
    }

    public struct AdminCap has key {  
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
            rewards_total_parts: 0,  
            rewards_per_share: 0,  
            total_rewards: balance::zero<CODE>()  
        });

        transfer::share_object(UserRegistry{
            id: object::new(ctx),
            users: table::new(ctx)
        });

        transfer::transfer(AdminCap {id: object::new(ctx)}, tx_context::sender(ctx));
    }

    public entry fun set_reward(_: &AdminCap, reward_state: &mut RewardState, duration: u64, reward: Coin<CODE>, clock: &Clock) {
        let timestamp = clock::timestamp_ms(clock);
        assert!(reward_state.finish_at < timestamp, ERewardDurationNotExpired);
        reward_state.duration = duration;
        reward_state.reward_rate = reward.balance().value() / reward_state.duration;
        let balance = coin::into_balance(reward);
        balance::join(&mut reward_state.total_rewards, balance);
        reward_state.updated_at = timestamp;
        reward_state.finish_at = timestamp + reward_state.duration;
    }

    public entry fun stake(nft: PFP, reward_state: &mut RewardState, user_registry: &mut UserRegistry, clock: &Clock, ctx: &mut TxContext) {
        let nft_rarity = PFP_NFT::get_rarity(&nft) as u64;
        update_global_state_general(reward_state, clock);
        reward_state.rewards_total_parts = reward_state.rewards_total_parts + nft_rarity + 1;
        update_user_state_general_on_stake(nft, reward_state, user_registry, ctx);
    }  

    public entry fun claim_rewards(reward_state: &mut RewardState, user_registry: &mut UserRegistry, ctx: &mut TxContext) {
        let caller = tx_context::sender(ctx);
        let user_state = user_registry.users.borrow_mut(caller);
        let current_rewards = (reward_state.rewards_per_share - user_state.last_rewards_per_share) * user_state.stakedParts / DIVISION_SAFETY_CONSTANT;
        user_state.last_rewards_per_share = reward_state.rewards_per_share;
        
        let pendingRewards = user_state.pendingRewards.value() + current_rewards;
        let total_rewards_coin = coin::take<CODE>(&mut reward_state.total_rewards, pendingRewards, ctx);
        transfer::public_transfer(total_rewards_coin, tx_context::sender(ctx));
    } 

    fun update_global_state_general(reward_state: &mut RewardState, clock: &Clock) {
        let timestamp = clock::timestamp_ms(clock);
        assert!(timestamp > reward_state.updated_at, EInvalidTimestamp);
        reward_state.rewards_per_share = reward_state.rewards_per_share + (timestamp - reward_state.updated_at) * DIVISION_SAFETY_CONSTANT / reward_state.rewards_total_parts;
        reward_state.updated_at = timestamp;
    }
    
    fun update_user_state_general_on_stake(nft: PFP, reward_state: &RewardState, user_registry: &mut UserRegistry, ctx: &mut TxContext) {
        let caller = tx_context::sender(ctx);
        let nft_rarity = PFP_NFT::get_rarity(&nft) as u64;
        if (!table::contains(&user_registry.users, caller)) {
            let userState = UserState {
                id: object::new(ctx),
                address: caller,
                stakedNfts: vector::singleton(nft),
                stakedParts: nft_rarity + 1,
                last_rewards_per_share: reward_state.rewards_per_share,
                pendingRewards: balance::zero<CODE>()
            }; 
            table::add(&mut user_registry.users, caller, userState);
        } else {
            let user_state = user_registry.users.borrow_mut(caller);
            vector::push_back(&mut user_state.stakedNfts, nft);
            user_state.stakedParts = user_state.stakedParts + nft_rarity + 1;
            user_state.last_rewards_per_share = reward_state.rewards_per_share;
        }
    }
}