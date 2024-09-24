module sui_staking::code {
    use sui::coin::{Self, TreasuryCap};

    public struct CODE has drop {}

    fun init(witness: CODE, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(witness, 6, b"CODE", b"", b"", option::none(), ctx);
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, ctx.sender())
    }

    public fun mint(
        treasury_cap: &mut TreasuryCap<CODE>, 
        amount: u64, 
        recipient: address, 
        ctx: &mut TxContext,
    ) {
        let coin = coin::mint(treasury_cap, amount, ctx);
        transfer::public_transfer(coin, recipient)
    }
}