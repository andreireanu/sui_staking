module sui_staking::staking {

    use sui::balance::{Self, Balance};
    use sui_staking::PFP_NFT::{Self, PFP};
    use sui_staking::code::CODE;
    use sui::clock::{Self, Clock};
    use sui::coin::{Self, Coin};
    use sui::table::{Self, Table};

    /// Every staked NFT has a reward multiplier according to its rarity:
    /// Common: 1
    /// Rare: 2
    /// Epic: 3
    /// Legendary: 4
    /// 

    public struct RewardState has key {
        id: UID,
        duration: u64, // Set by the Owner: Duration of rewards to be paid out (in seconds)
        finishAt: u64, // Timestamp of when the rewards finish
        updatedAt: u64, // Minimum of last updated time and reward finish time
        rewardRate: u64, // Reward to be paid out per second: determined by the duration & amount of rewards
        rewardsTotalParts : u64, // Total parts of rewards to be distributed
        rewardsPerShare: u64, // Rewards per share
        totalRewards: Balance<CODE>, // Total rewards to be distributed
    }

    public struct UserState has store, key {
        id: UID,
        address: address,
        stakedNfts: vector<PFP>, // Mapping that keeps track of users' staked NFTs
        stakedParts: u64,
        lastRewardsPerShare: u64,
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
    const EZeroRewardRate: u64 = 101;
    const EZeroAmount: u64 = 102;
    const ELowRewardsTreasuryBalance: u64 = 103;
    const ERequestedAmountExceedsStaked: u64 = 104;
    const ENoRewardsToClaim: u64 = 105;
    const ENoStakedTokens: u64 = 106;
    const ENoPriorTokenStake: u64 = 107;

    fun init (ctx: &mut TxContext) {
        transfer::share_object(RewardState{
            id: object::new(ctx),
            duration: 0,  
            finishAt: 0,  
            updatedAt: 0,   
            rewardRate: 0,  //
            rewardsTotalParts: 0,  
            rewardsPerShare: 0,  
            totalRewards: balance::zero<CODE>() //
        });

        transfer::share_object(UserRegistry{
            id: object::new(ctx),
            users: table::new(ctx)
        });

        transfer::transfer(AdminCap {id: object::new(ctx)}, tx_context::sender(ctx));
    }

    public entry fun setReward(_: &AdminCap, rewardState: &mut RewardState, duration: u64, reward: Coin<CODE>, clock: &Clock) {
        let timestamp = clock::timestamp_ms(clock);
        assert!(rewardState.finishAt < timestamp, ERewardDurationNotExpired);
        rewardState.duration = duration;
        rewardState.rewardRate = reward.balance().value() / rewardState.duration;
        let balance = coin::into_balance(reward);
        balance::join(&mut rewardState.totalRewards, balance);
        rewardState.updatedAt = timestamp;
        rewardState.finishAt = timestamp + rewardState.duration;
    }

    public entry fun stake(nft: PFP, rewardState: &mut RewardState, userRegistry: &mut UserRegistry, clock: &Clock, ctx: &mut TxContext) {
        let caller = tx_context::sender(ctx);
        let nft_rarity = PFP_NFT::get_rarity(&nft) as u64;
        if (!table::contains(&userRegistry.users, caller)) {
            let userState = UserState {
                id: object::new(ctx),
                address: caller,
                stakedNfts: vector::singleton(nft),
                stakedParts: nft_rarity + 1,
                lastRewardsPerShare: 0,
                pendingRewards: balance::zero<CODE>()
            }; 
            table::add(&mut userRegistry.users, caller, userState);
        } else {
            let user_state = userRegistry.users.borrow_mut(caller);
            vector::push_back(&mut user_state.stakedNfts, nft);
            user_state.stakedParts = user_state.stakedParts + nft_rarity + 1;
        }
    }

}