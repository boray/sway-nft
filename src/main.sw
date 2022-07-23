// ANCHOR: body
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
struct Sent {
    from: Address,
    to: Address,
    tokenId: u64,
}

////////////////////////////////////////
// ABI method declarations
////////////////////////////////////////

/// ABI for a subcurrency.
abi Token {
    // Mint new tokens and send to an address.
    // Can only be called by the contract creator.
    #[storage(read, write)]fn mint(receiver: Address, tokenID: u64, tokenURI: Address);

    // Sends an amount of an existing token.
    // Can be called from any address.
    #[storage(read, write)]fn send(receiver: Address, tokenID: u64);

    #[storage(read, write)]fn setTokenURI( tokenId: u64);
    #[storage(read, write)]fn getTokenURI( tokenId: u64);

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
    #[storage(read, write)]fn mint(receiver: Address, tokenID: u64, tokenURI: Address) {
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
        storage.balances.insert(receiver, storage.balances.get(receiver) + 1);
        storage.owners.insert(Address, tokenID);
        storage.tokenuris.insert(tokenID, tokenURI);
    }

    #[storage(read, write)]fn setTokenURI( tokenId: u64) {

        assert(storage.owners.get(tokenID) = msg_sender());

    }

    #[storage(read, write)]fn send(receiver: Address, tokenID: u64) {
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

        // Increase the balance od receiver
        storage.balances.insert(receiver, storage.balances.get(receiver) + 1);

        log(Sent {
            from: sender, to: receiver, tokenId: tokenID
        });
    }
}
// ANCHOR_END: body
