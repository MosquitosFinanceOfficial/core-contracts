#[test_only]
module MasterChefDeployer::AirdropTests {
    #[test_only]
    use std::signer;
    #[test_only]
    use std::string::utf8;
    #[test_only]
    use std::debug;
    #[test_only]
    use std::vector;
    #[test_only]
    use aptos_framework::genesis;
    #[test_only]
    use aptos_framework::account::create_account_for_test;
    #[test_only]
    use aptos_framework::coin::{
        Self, MintCapability, FreezeCapability, BurnCapability
    };

    #[test_only]
    use AirdropDeployer::Airdrop::{ Self, SUCKR };

    #[test_only]
    const INIT_FAUCET_COIN:u64 = 10000;

    struct Caps<phantom X> has key {
        mint: MintCapability<X>,
        freeze: FreezeCapability<X>,
        burn: BurnCapability<X>,
    }

    #[test_only]
    public entry fun test_module_init(admin: &signer) {
        Airdrop::initialize(admin);
    }

    #[test_only]
    public entry fun test_coin_init(admin: &signer, someone: &signer, another: &signer) {
        genesis::setup();
        create_account_for_test(signer::address_of(admin));
        create_account_for_test(signer::address_of(someone));
        create_account_for_test(signer::address_of(another));
        {
            let (burn_cap, freeze_cap, mint_cap) = coin::initialize<SUCKR>(
                admin,
                utf8(b"Mosquitos Coin"),
                utf8(b"SUCKR"),
                6,
                true
            );
            coin::register<SUCKR>(admin);
            let coins = coin::mint<SUCKR>(INIT_FAUCET_COIN, &mint_cap);
            coin::deposit(signer::address_of(admin), coins);
    
            move_to(admin, Caps<SUCKR> {
                mint: mint_cap,
                freeze: freeze_cap,
                burn: burn_cap
            });
        }
    }

    #[test(admin = @AirdropDeployer, someone = @0x11, another = @0x22)]
    public entry fun test_claim_airdrop(admin: &signer, someone: &signer, another: &signer) {
        test_coin_init(admin, someone, another);
        test_module_init(admin);

        let address_list:vector<address> = vector::empty();
        let amount_list:vector<u64> = vector::empty();
        vector::push_back<address>(&mut address_list, signer::address_of(someone));
        vector::push_back<u64>(&mut amount_list, 521);
        vector::push_back<address>(&mut address_list, signer::address_of(another));
        vector::push_back<u64>(&mut amount_list, 255);

        Airdrop::add_airdrop_list(admin, address_list, amount_list);
        // Airdrop::add_custom_airdrop_test_only(admin, signer::address_of(someone), 555);
        Airdrop::start_airdrop(admin, 0);
        Airdrop::claim_airdrop(someone);
        Airdrop::claim_airdrop(another);
        let someone_balance = coin::balance<SUCKR>(signer::address_of(someone));
        debug::print(&someone_balance);
        let another_balance = coin::balance<SUCKR>(signer::address_of(another));
        debug::print(&another_balance);

        Airdrop::burn_unclaimed_airdrop(admin);
        let admin_balance = coin::balance<SUCKR>(signer::address_of(admin));
        debug::print(&admin_balance);
    }
}