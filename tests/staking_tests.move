#[test_only]
module sui_staking::staking_tests{

    use sui::test_scenario;
    use sui_staking::PFP_NFT ;

    #[test]
    fun test_example(){

        let owner = @0x1;
        let alice = @0x2;
        let bob = @0x3;

        let mut scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;
        {   // Owner deploys the contracts
            let ctx = test_scenario::ctx(scenario);
            PFP_NFT::init_for_testing(ctx);
        };
        test_scenario::end(scenario_val);

    }

}