module MasterChefDeployer::MosquitoCoin {
    use std::signer;
    use std::event;
    use std::vector;
    use std::string::utf8;
    use aptos_framework::timestamp;
    use aptos_framework::coin::{
        Self, Coin, MintCapability, FreezeCapability, BurnCapability
    };
    use aptos_framework::account::{ Self };

    /// When user is not admin
    const ERR_FORBIDDEN: u64 = 106;
    /// When the value is not greater than zero
    const ERR_MUST_BE_GREATER_THAN_ZERO: u64 = 107;

    const INIT_SUPPLY: u64 = 17526666;
    const TOKEN_DECIMALS: u64 = 100000000;

    const DEPLOYER_ADDRESS: address = @MasterChefDeployer;
    const RESOURCE_ACCOUNT_ADDRESS: address = @ResourceAccountDeployer;

    /// Reward coin structure
    struct SUCKR {}

    /// Store initial coin supply and distribution info
    struct SupplyInfo has key {
        airdrop_address: address,
        airdrop_amount: u64,
        marketing_address: address,
        marketing_amount: u64,
        presale_address: address,
        presale_amount: u64,
        public_sale_address: address,
        public_sale_amount: u64,
        cex_address: address,
        cex_amount: u64,
        team_address: address,
        team_amount: u64,
        treasury: Coin<SUCKR>
    }

    // Store locked coins info
    struct LockedSUCKR has key {
        coins: Coin<SUCKR>,
        vec: vector<LockedItem>
    }

    struct LockedItem has store, drop, key {
        amount: u64,
        owner: address,
        unlock_timestamp: u64
    }

    /// Store min/burn/freeze capabilities for reward token under resource account
    struct Caps<phantom CoinType> has key {
        admin_address: address,
        farm_address: address,
        direct_mint: bool,
        mint: MintCapability<CoinType>,
        freeze: FreezeCapability<CoinType>,
        burn: BurnCapability<CoinType>,
        mint_event: event::EventHandle<MintBurnEvent>,
        burn_event: event::EventHandle<MintBurnEvent>,
    }

    struct MintBurnEvent has drop, store {
        value: u64,
    }

    fun init_module(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<SUCKR>(
            admin,
            utf8(b"SUCKR"),
            utf8(b"SUCKR"),
            8,
            true,
        );
        let coins = coin::mint<SUCKR>(INIT_SUPPLY * TOKEN_DECIMALS, &mint_cap);

        move_to(admin, Caps<SUCKR> {
            admin_address: admin_addr,
            farm_address: RESOURCE_ACCOUNT_ADDRESS,
            direct_mint: true,
            mint: mint_cap,
            burn: burn_cap,
            freeze: freeze_cap,
            mint_event: account::new_event_handle<MintBurnEvent>(admin),
            burn_event: account::new_event_handle<MintBurnEvent>(admin),
        });
        move_to(admin, SupplyInfo {
            airdrop_address: admin_addr,
            airdrop_amount: 26666 * TOKEN_DECIMALS,
            marketing_address: admin_addr,
            marketing_amount: 3000000 * TOKEN_DECIMALS,
            presale_address: admin_addr,
            presale_amount: 1500000 * TOKEN_DECIMALS,
            public_sale_address: admin_addr,
            public_sale_amount: 1000000 * TOKEN_DECIMALS,
            cex_address: admin_addr,
            cex_amount: 8000000 * TOKEN_DECIMALS,
            team_address: admin_addr,
            team_amount: 4000000 * TOKEN_DECIMALS,
            treasury: coins,
        });
        move_to(admin, LockedSUCKR {
            coins: coin::zero(),
            vec: vector::empty(),
        })
    }

    // Set admin address
    public entry fun set_admin_address(admin: &signer, addr: address) acquires Caps {
        let caps = borrow_global_mut<Caps<SUCKR>>(DEPLOYER_ADDRESS);
        assert!(signer::address_of(admin) == caps.admin_address, ERR_FORBIDDEN);
        caps.admin_address = addr;
    }

    // Set farm address
    public entry fun set_farm_address(admin: &signer, addr: address) acquires Caps {
        let caps = borrow_global_mut<Caps<SUCKR>>(DEPLOYER_ADDRESS);
        assert!(signer::address_of(admin) == caps.admin_address, ERR_FORBIDDEN);
        caps.farm_address = addr;
    }

    // Set airdrop address for withdrawing the SUCKR token
    public entry fun set_airdrop_address(admin: &signer, addr: address) acquires SupplyInfo, Caps {
        let supply_info = borrow_global_mut<SupplyInfo>(DEPLOYER_ADDRESS);
        let caps = borrow_global<Caps<SUCKR>>(DEPLOYER_ADDRESS);
        assert!(signer::address_of(admin) == caps.admin_address, ERR_FORBIDDEN);
        supply_info.airdrop_address = addr;
    }

    public entry fun set_marketing_address(admin: &signer, addr: address) acquires SupplyInfo, Caps {
        let supply_info = borrow_global_mut<SupplyInfo>(DEPLOYER_ADDRESS);
        let caps = borrow_global<Caps<SUCKR>>(DEPLOYER_ADDRESS);
        assert!(signer::address_of(admin) == caps.admin_address, ERR_FORBIDDEN);
        supply_info.marketing_address = addr;
    }

    public entry fun set_presale_address(admin: &signer, addr: address) acquires SupplyInfo, Caps {
        let supply_info = borrow_global_mut<SupplyInfo>(DEPLOYER_ADDRESS);
        let caps = borrow_global<Caps<SUCKR>>(DEPLOYER_ADDRESS);
        assert!(signer::address_of(admin) == caps.admin_address, ERR_FORBIDDEN);
        supply_info.presale_address = addr;
    }

    public entry fun set_public_sale_address(admin: &signer, addr: address) acquires SupplyInfo, Caps {
        let supply_info = borrow_global_mut<SupplyInfo>(DEPLOYER_ADDRESS);
        let caps = borrow_global<Caps<SUCKR>>(DEPLOYER_ADDRESS);
        assert!(signer::address_of(admin) == caps.admin_address, ERR_FORBIDDEN);
        supply_info.public_sale_address = addr;
    }

    public entry fun set_cex_address(admin: &signer, addr: address) acquires SupplyInfo, Caps {
        let supply_info = borrow_global_mut<SupplyInfo>(DEPLOYER_ADDRESS);
        let caps = borrow_global<Caps<SUCKR>>(DEPLOYER_ADDRESS);
        assert!(signer::address_of(admin) == caps.admin_address, ERR_FORBIDDEN);
        supply_info.cex_address = addr;
    }

    public entry fun set_team_address(admin: &signer, addr: address) acquires SupplyInfo, Caps {
        let supply_info = borrow_global_mut<SupplyInfo>(DEPLOYER_ADDRESS);
        let caps = borrow_global<Caps<SUCKR>>(DEPLOYER_ADDRESS);
        assert!(signer::address_of(admin) == caps.admin_address, ERR_FORBIDDEN);
        supply_info.team_address = addr;
    }

    // Withdraw SUCKR for airdrop
    public entry fun withdraw_SUCKR_for_airdrop(account: &signer) acquires SupplyInfo {
        let supply_info = borrow_global_mut<SupplyInfo>(DEPLOYER_ADDRESS);
        let user_addr = signer::address_of(account);
        assert!(user_addr == supply_info.airdrop_address, ERR_FORBIDDEN);
        assert!(supply_info.airdrop_amount > 0, ERR_MUST_BE_GREATER_THAN_ZERO);
        
        let coins = coin::extract(&mut supply_info.treasury, supply_info.airdrop_amount);
        if (!coin::is_account_registered<SUCKR>(user_addr)) {
            coin::register<SUCKR>(account);
        };
        supply_info.airdrop_amount = 0;
        coin::deposit<SUCKR>(user_addr, coins);
    }

    
    public entry fun withdraw_SUCKR_for_marketing(account: &signer) acquires SupplyInfo {
        let supply_info = borrow_global_mut<SupplyInfo>(DEPLOYER_ADDRESS);
        let user_addr = signer::address_of(account);
        assert!(user_addr == supply_info.marketing_address, ERR_FORBIDDEN);
        assert!(supply_info.marketing_amount > 0, ERR_MUST_BE_GREATER_THAN_ZERO);
        
        let coins = coin::extract(&mut supply_info.treasury, supply_info.marketing_amount);
        if (!coin::is_account_registered<SUCKR>(user_addr)) {
            coin::register<SUCKR>(account);
        };
        supply_info.marketing_amount = 0;
        coin::deposit<SUCKR>(user_addr, coins);
    }

    public entry fun withdraw_SUCKR_for_presale(account: &signer) acquires SupplyInfo {
        let supply_info = borrow_global_mut<SupplyInfo>(DEPLOYER_ADDRESS);
        let user_addr = signer::address_of(account);
        assert!(user_addr == supply_info.presale_address, ERR_FORBIDDEN);
        assert!(supply_info.presale_amount > 0, ERR_MUST_BE_GREATER_THAN_ZERO);
        
        let coins = coin::extract(&mut supply_info.treasury, supply_info.presale_amount);
        if (!coin::is_account_registered<SUCKR>(user_addr)) {
            coin::register<SUCKR>(account);
        };
        supply_info.presale_amount = 0;
        coin::deposit<SUCKR>(user_addr, coins);
    }

    public entry fun withdraw_SUCKR_for_public_sale(account: &signer) acquires SupplyInfo {
        let supply_info = borrow_global_mut<SupplyInfo>(DEPLOYER_ADDRESS);
        let user_addr = signer::address_of(account);
        assert!(user_addr == supply_info.public_sale_address, ERR_FORBIDDEN);
        assert!(supply_info.public_sale_amount > 0, ERR_MUST_BE_GREATER_THAN_ZERO);
        
        let coins = coin::extract(&mut supply_info.treasury, supply_info.public_sale_amount);
        if (!coin::is_account_registered<SUCKR>(user_addr)) {
            coin::register<SUCKR>(account);
        };
        supply_info.public_sale_amount = 0;
        coin::deposit<SUCKR>(user_addr, coins);
    }

    public entry fun withdraw_SUCKR_for_cex(account: &signer) acquires SupplyInfo {
        let supply_info = borrow_global_mut<SupplyInfo>(DEPLOYER_ADDRESS);
        let user_addr = signer::address_of(account);
        assert!(user_addr == supply_info.cex_address, ERR_FORBIDDEN);
        assert!(supply_info.cex_amount > 0, ERR_MUST_BE_GREATER_THAN_ZERO);
        
        let coins = coin::extract(&mut supply_info.treasury, supply_info.cex_amount);
        if (!coin::is_account_registered<SUCKR>(user_addr)) {
            coin::register<SUCKR>(account);
        };
        supply_info.cex_amount = 0;
        coin::deposit<SUCKR>(user_addr, coins);
    }

    public entry fun withdraw_SUCKR_for_team(account: &signer) acquires SupplyInfo {
        let supply_info = borrow_global_mut<SupplyInfo>(DEPLOYER_ADDRESS);
        let user_addr = signer::address_of(account);
        assert!(user_addr == supply_info.team_address, ERR_FORBIDDEN);
        assert!(supply_info.team_amount > 0, ERR_MUST_BE_GREATER_THAN_ZERO);
        
        let coins = coin::extract(&mut supply_info.treasury, supply_info.team_amount);
        if (!coin::is_account_registered<SUCKR>(user_addr)) {
            coin::register<SUCKR>(account);
        };
        supply_info.team_amount = 0;
        coin::deposit<SUCKR>(user_addr, coins);
    }

    public entry fun lock_SUCKR(
        account: &signer,
        amount: u64,
        unlock_timestamp: u64
    ) acquires LockedSUCKR {
        let locked_info = borrow_global_mut<LockedSUCKR>(DEPLOYER_ADDRESS);
        let current_timestamp = timestamp::now_seconds();
        assert!(current_timestamp < unlock_timestamp, ERR_FORBIDDEN);
        
        let coins_in = coin::withdraw<SUCKR>(account, amount);
        let new_locked_item = LockedItem {
            amount,
            owner: signer::address_of(account),
            unlock_timestamp
        };
        coin::merge(&mut locked_info.coins, coins_in);
        vector::push_back<LockedItem>(&mut locked_info.vec, new_locked_item);
    }

    public entry fun unlock_SUCKR(account: &signer) acquires LockedSUCKR {
        let locked_info = borrow_global_mut<LockedSUCKR>(DEPLOYER_ADDRESS);
        let current_timestamp = timestamp::now_seconds();
        let temp_vec: vector<u64> = vector::empty();
        let len = vector::length(&locked_info.vec);
        let i: u64 = 0;
        while (i < len) {
            let locked_item = vector::borrow<LockedItem>(&locked_info.vec, i);
            if (locked_item.owner == signer::address_of(account)) {
                if (locked_item.unlock_timestamp <= current_timestamp) {
                    let coins_out = coin::extract(&mut locked_info.coins, locked_item.amount);
                    coin::deposit<SUCKR>(signer::address_of(account), coins_out);
                    vector::push_back<u64>(&mut temp_vec, i);
                };
            };
            i = i + 1;
        };
        i = 0;
        len = vector::length(&temp_vec);
        while (i < len) {
            let pos = vector::borrow<u64>(&temp_vec, i);
            vector::remove<LockedItem>(&mut locked_info.vec, *pos);
            i = i + 1;
        }
    }

    // Mints new coin on resource account
    public entry fun mint_SUCKR(
        admin: &signer,
        amount: u64,
        to: address,
    ) acquires Caps {
        let caps = borrow_global_mut<Caps<SUCKR>>(DEPLOYER_ADDRESS);
        assert!(signer::address_of(admin) == caps.admin_address, ERR_FORBIDDEN);
        assert!(caps.direct_mint, ERR_FORBIDDEN);

        let coins = coin::mint<SUCKR>(amount, &caps.mint);
        coin::deposit(to, coins);
        event::emit_event(&mut caps.mint_event, MintBurnEvent {
            value: amount,
        });
    }

    // Mints new coin on resource account
    public fun mint_farm_SUCKR(
        admin: &signer,
        amount: u64
    ): Coin<SUCKR> acquires Caps {
        let admin_addr = signer::address_of(admin);
        if (!coin::is_account_registered<SUCKR>(admin_addr)) {
            coin::register<SUCKR>(admin);
        };
        let caps = borrow_global_mut<Caps<SUCKR>>(DEPLOYER_ADDRESS);
        assert!(admin_addr == caps.farm_address, ERR_FORBIDDEN);
        let coins = coin::mint<SUCKR>(amount, &caps.mint);
        coins
    }

    // Burn the coins on a account
    public entry fun burn_SUCKR(
        user_account: &signer,
        amount: u64
    ) acquires Caps {
        let caps = borrow_global_mut<Caps<SUCKR>>(DEPLOYER_ADDRESS);
        let burn_coins = coin::withdraw<SUCKR>(user_account, amount);
        coin::burn<SUCKR>(burn_coins, &caps.burn);
        event::emit_event(&mut caps.burn_event, MintBurnEvent {
            value: amount,
        });
    }

    // Only resource_account should call this
    public entry fun register_SUCKR(account: &signer) {
        let account_addr = signer::address_of(account);
        if (!coin::is_account_registered<SUCKR>(account_addr)) {
            coin::register<SUCKR>(account);
        };
    }

    // After call this, direct mint will be disabled forever
    public entry fun set_disable_direct_mint(admin: &signer) acquires Caps {
        let caps = borrow_global_mut<Caps<SUCKR>>(DEPLOYER_ADDRESS);
        assert!(signer::address_of(admin) == caps.admin_address, ERR_FORBIDDEN);
        caps.direct_mint = false;
    }
}
