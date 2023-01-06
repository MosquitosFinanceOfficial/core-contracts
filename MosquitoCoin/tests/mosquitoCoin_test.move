#[test_only]
module MasterChefDeployer::MosquitosCoinTests {
    #[test_only]
    use std::signer;
    #[test_only]
    use std::debug;
    #[test_only]
    use aptos_framework::genesis;
    #[test_only]
    use aptos_framework::account::create_account_for_test;
    #[test_only]
    use aptos_framework::coin::{
        Self
    };

    #[test_only]
    use MasterChefDeployer::MosquitoCoin::{ Self, SUCKR };

    #[test_only]
    const INIT_FAUCET_COIN:u64 = 23862;

    #[test_only]
    public entry fun test_module_init(admin: &signer) {
        MosquitoCoin::initialize(admin);
    }

    #[test(admin = @MasterChefDeployer, resource_account = @ResourceAccountDeployer)]
    public entry fun test_mint_coin(admin: &signer, resource_account: &signer) {
        genesis::setup();
        create_account_for_test(signer::address_of(admin));
        create_account_for_test(signer::address_of(resource_account));
        test_module_init(admin);
        let coins = MosquitoCoin::mint_farm_SUCKR(resource_account, INIT_FAUCET_COIN);
        coin::deposit<SUCKR>(signer::address_of(resource_account), coins);
        let cur_user_balance = coin::balance<SUCKR>(signer::address_of(resource_account));
        debug::print(&cur_user_balance);

        MosquitoCoin::register_SUCKR(admin);
        MosquitoCoin::burn_SUCKR(resource_account, 120);
        let coins = coin::withdraw<SUCKR>(resource_account, 862);
        coin::deposit<SUCKR>(signer::address_of(admin), coins);
        cur_user_balance = coin::balance<SUCKR>(signer::address_of(resource_account));
        debug::print(&cur_user_balance);
    }

    #[test(admin = @MasterChefDeployer, airdrop_account = @0x12, marketing_account = @0x15)]
    public entry fun test_lock_coin(
        admin: &signer,
        airdrop_account: &signer,
        marketing_account: &signer
    ) {
        genesis::setup();
        create_account_for_test(signer::address_of(admin));
        create_account_for_test(signer::address_of(airdrop_account));
        create_account_for_test(signer::address_of(marketing_account));
        
        test_module_init(admin);
        
        MosquitoCoin::set_airdrop_address(admin, signer::address_of(airdrop_account));
        MosquitoCoin::set_marketing_address(admin, signer::address_of(marketing_account));
        MosquitoCoin::withdraw_SUCKR_for_airdrop(airdrop_account);
        MosquitoCoin::withdraw_SUCKR_for_marketing(marketing_account);
        
        MosquitoCoin::lock_SUCKR(airdrop_account, 2666599999989, 50);
        MosquitoCoin::lock_SUCKR(airdrop_account, 11, 90);
        MosquitoCoin::lock_SUCKR(marketing_account, 300000000000000, 50);

        MosquitoCoin::unlock_SUCKR(airdrop_account);
        let airdrop_balance = coin::balance<SUCKR>(signer::address_of(airdrop_account));
        debug::print(&airdrop_balance);
        let marketing_balance = coin::balance<SUCKR>(signer::address_of(marketing_account));
        debug::print(&marketing_balance);
    }
}