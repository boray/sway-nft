contract;

use std::{
    address::Address,
    assert::assert,
    chain::auth::{AuthError, msg_sender},
    hash::sha256,
    identity::Identity,
    logging::log,
    result::Result,
    revert::revert,
    storage::StorageMap,
};

////////////////////////////////////////
// Event declarations
////////////////////////////////////////

// Events allow clients to react to changes in the contract.
// Unlike Solidity, events are simply structs.
// Note: Logging of arbitrary stack types is supported, however they cannot yet
//  be decoded on the SDK side.

/// Emitted when a token is sent.

struct Mint {
    to: Address,
    tokenID: u64,
}

struct Burn {
    tokenID: u64,
}

struct Transfer {
    from: Address,
    to: Address,
    tokenID: u64,
}
////////////////////////////////////////
// ABI method declarations
////////////////////////////////////////

/// ABI for a subcurrency.
abi Token {
    #[storage(read, write)]fn mint(receiver: Address, tokenID: u64, tokenURI: Address);
    #[storage(read, write)]fn burn(tokenID: u64);
    #[storage(read, write)]fn transfer(receiver: Address, tokenID: u64);
    #[storage(read, write)]fn setTokenURI( tokenID: u64);
    #[storage(read)]fn getTokenURI(tokenID: u64);
    #[storage(read)]fn ownerOf(tokenID: u64);
    #[storage(read)]fn balanceOf(address: Address);
}

////////////////////////////////////////
// Constants
////////////////////////////////////////

/// Address of contract creator.
const MINTER: b256 = 0x9299da6c73e6dc03eeabcce242bb347de3f5f56cd1c70926d76526d7ed199b8b;

////////////////////////////////////////
// Contract storage
////////////////////////////////////////

// Contract storage persists across transactions.
storage {
    owners: StorageMap<u64,
    Address> = StorageMap {
    },
    balances: StorageMap<Address,
    u64> = StorageMap {
    },
    tokenuris: StorageMap<b256,
    Address> = StorageMap {
    },
}

////////////////////////////////////////
// ABI definitions
////////////////////////////////////////

/// Contract implements the `Token` ABI.
impl Token for Contract {

    #[storage(read, write)]fn mint(to: Address, tokenID: u64, tokenURI: Address) {
        // Note: The return type of `msg_sender()` can be inferred by the
        // compiler. It is shown here for explicitness.
        let sender: Result<Identity, AuthError> = msg_sender();
        let sender: Address = match sender.unwrap() {
            Identity::Address(addr) => {
                assert(addr == ~Address::from(MINTER));
                addr
            },
            _ => {
                revert(0);
            },
        };

        // Increase the balance of receiver
        storage.balances.insert(to, storage.balances.get(to) + 1);
        storage.owners.insert(Address, tokenID);
        storage.tokenuris.insert(tokenID, tokenURI);

        log(Mint {
            to: to, tokenID: tokenID
        });
    }

    #[storage(read, write)]fn burn(tokenID: u64) {
        assert(storage.owners.get(tokenID) = msg_sender());
        storage.owners.insert(tokenID,0x0); // not sure with zero
        storage.balances.insert(storage.balances.get(msg_sender()) - 1);
        storage.tokenuris.insert(tokenID,0x0); // not sure with zero 

        log(Burn {
            tokenID: tokenID
        });
    }

    #[storage(read, write)]fn transfer(receiver: Address, tokenID: u64) {
        // Note: The return type of `msg_sender()` can be inferred by the
        // compiler. It is shown here for explicitness.
        let sender: Result<Identity, AuthError> = msg_sender();
        let sender: Address = match sender.unwrap() {
            Identity::Address(addr) => {
                assert(addr == ~Address::from(MINTER));
                addr
            },
            _ => {
                revert(0);
            },
        };

        assert(storage.owners.get(tokenID) = sender);
        
        storage.balances.insert(sender, sender_amount - 1);
        storage.owners.insert(tokenID,receiver);
        storage.balances.insert(receiver, storage.balances.get(receiver) + 1);

        log(Transfer {
            from: sender, to: receiver, tokenID: tokenID
        });
    }

    #[storage(read, write)]fn setTokenURI( tokenID: u64) {
        assert(storage.owners.get(tokenID) = msg_sender());
        storage.owners.insert(Address, tokenID);
    }

    #[storage(read)]fn getTokenURI(tokenID: u64) {
        storage.tokenuris.get(tokenID);
    }

    #[storage(read)]fn ownerOf(tokenId: u64) {
        storage.owners.get(tokenID)
    }

    #[storage(read)]fn balanceOf(address: Address) {
        storage.balances.get(address)
    }

}

