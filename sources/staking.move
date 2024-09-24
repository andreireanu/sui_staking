module sui_staking::staking {

    use sui::transfer;
    use sui::vec_map::{Self, VecMap};
    use sui::balance::{Self, Balance};
    use sui_staking::PFP_NFT::{PFP, PFPState};
    use sui_staking::code::CODE;
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::coin::{Self, Coin};

    public struct RewardState has key {
        id: UID,
        duration: u64, // Set by the Owner: Duration of rewards to be paid out (in seconds)
        finishAt: u64, // Timestamp of when the rewards finish
        updatedAt: u64, // Minimum of last updated time and reward finish time
        rewardRate: u64, // Reward to be paid out per second: determined by the duration & amount of rewards
    }

    public struct UserState has key {
        id: UID,
        rewardPerTokenStored: u64, // Sum of (reward rate * dt * 1^(token_decimal) / total staked supply) where dt is the time difference between current time and last updated time
        userRewardPerTokenPaid: VecMap<address, u64>, // Mapping that keeps track of users' rewardPerTokenStored
        stakedNft: VecMap<address, PFP>, // Mapping that keeps track of users' staked amount 
        rewards: VecMap<address, u64>, // Mapping that keeps track of users' rewards to be claimed
    }

    public struct Treasury has key {
        id: UID,
        rewardsTreasury: Balance<CODE>, 
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


    public struct RewardAdded has copy, drop{
        reward: u64
    }

    public struct RewardDurationUpdated has copy, drop {
         newDuration: u64
    }

    public struct Staked has copy, drop{
        user: address,
        amount: u64
    }

    public struct Withdrawn has copy, drop {
        user: address,
        amount: u64
    }

    public struct RewardPaid has copy, drop {
        user: address,
        reward: u64
    }

    fun init (ctx: &mut TxContext) {
       
        transfer::share_object(RewardState{
            id: object::new(ctx),
            duration: 0,
            finishAt: 0,
            updatedAt: 0,
            rewardRate: 0
        });

        transfer::share_object(UserState{
            id: object::new(ctx),
            rewardPerTokenStored: 0,
            userRewardPerTokenPaid: vec_map::empty<address, u64>(),
            stakedNft: vec_map::empty<address, PFP>(),
            rewards: vec_map::empty<address, u64>()
        });

        transfer::share_object(Treasury{
            id: object::new(ctx),
            rewardsTreasury: balance::zero<CODE>(),
        });

        transfer::transfer(AdminCap {id: object::new(ctx)}, tx_context::sender(ctx));
    }

    /* ========== ADMIN FUNCTIONS ========== */

    public entry fun setRewardDuration(_: &AdminCap, rewardState: &mut RewardState, duration: u64, clock: &Clock) {
         // Ensure that the reward duration has expired
        assert!(rewardState.finishAt < clock::timestamp_ms(clock), ERewardDurationNotExpired);
        rewardState.duration = duration;
        event::emit(RewardDurationUpdated{newDuration: duration});
    }

 

}