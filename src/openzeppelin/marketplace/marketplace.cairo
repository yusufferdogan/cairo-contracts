use starknet::StorageAccess;
use starknet::StorageBaseAddress;
use starknet::SyscallResult;
use starknet::storage_read_syscall;
use starknet::storage_write_syscall;
use starknet::storage_address_from_base_and_offset;

use starknet::contract_address::ContractAddressIntoFelt252;
use starknet::contract_address::Felt252TryIntoContractAddress;
use starknet::ContractAddress;

use traits::Into;
use traits::TryInto;
use option::OptionTrait;

use integer::u256_from_felt252;
use integer::Felt252IntoU256;


#[abi]
trait IERC721 {
    fn transfer_from(from: ContractAddress, to: ContractAddress, token_id: u256);
    fn mint();
    fn approve(to: ContractAddress, token_id: u256);
    fn set_approval_for_all(operator: ContractAddress, approved: bool);
    fn is_approved_for_all(owner: ContractAddress, operator: ContractAddress) -> bool;
    fn get_approved(token_id: u256) -> ContractAddress;
    fn token_uri(token_id: u256) -> felt252;
    fn _base_uri() -> felt252;
    fn balance_of(account: ContractAddress) -> u256;
    fn owner_of(token_id: u256) -> ContractAddress;
    fn get_name() -> felt252;
    fn get_symbol() -> felt252;
}

#[abi]
trait IERC20 {
    fn name() -> felt252;
    fn symbol() -> felt252;
    fn decimals() -> u8;
    fn total_supply() -> u256;
    fn balance_of(account: ContractAddress) -> u256;
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
    fn approve(spender: ContractAddress, amount: u256) -> bool;
}
#[derive(Drop, Serde)]
struct Offer {
    bid_amount: u128,
    expires_at: u128
}

impl OfferStorageAccess of StorageAccess<Offer> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<Offer> {
        Result::Ok(
            Offer {
                bid_amount: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 0_u8)
                )?.try_into().unwrap(),
                expires_at: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 1_u8)
                )?.try_into().unwrap(),
            }
        )
    }

    fn write(address_domain: u32, base: StorageBaseAddress, value: Offer) -> SyscallResult::<()> {
        storage_write_syscall(
            address_domain,
            storage_address_from_base_and_offset(base, 0_u8),
            value.bid_amount.into()
        )?;
        storage_write_syscall(
            address_domain,
            storage_address_from_base_and_offset(base, 1_u8),
            value.expires_at.into()
        )
    }
}

#[derive(Drop, Serde)]
struct Listing {
    seller: ContractAddress,
    price: u128,
    expires_at: u128
}
impl ListingStorageAccess of StorageAccess<Listing> {
    fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult::<Listing> {
        Result::Ok(
            Listing {
                seller: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 0_u8)
                )?.try_into().unwrap(),
                price: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 1_u8)
                )?.try_into().unwrap(),
                expires_at: storage_read_syscall(
                    address_domain, storage_address_from_base_and_offset(base, 2_u8)
                )?.try_into().unwrap(),
            }
        )
    }

    fn write(address_domain: u32, base: StorageBaseAddress, value: Listing) -> SyscallResult::<()> {
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 0_u8), value.seller.into()
        )?;
        storage_write_syscall(
            address_domain, storage_address_from_base_and_offset(base, 1_u8), value.price.into()
        )?;
        storage_write_syscall(
            address_domain,
            storage_address_from_base_and_offset(base, 2_u8),
            value.expires_at.into()
        )
    }
}


#[contract]
mod Marketplace {
    use super::Offer;
    use super::Listing;
    use super::IERC20DispatcherTrait;
    use super::IERC20Dispatcher;
    use super::IERC721DispatcherTrait;
    use super::IERC721Dispatcher;

    use starknet::get_caller_address;
    use starknet::info::get_contract_address;
    use starknet::ContractAddress;
    use integer::BoundedU256;

    use debug::PrintTrait;

    struct Storage {
        _token: ContractAddress,
        //_listings[nft_contract_address][tokenId] = (SELLER,PRICE,EXPIRES_AT)
        _listings: LegacyMap<(ContractAddress, u256), Listing>,
        //_offers[nft_contract_address][bidder][nftId] = (bid_amount,expiresAt)
        _offers: LegacyMap<(ContractAddress, ContractAddress, u256), Offer>
    }

    #[constructor]
    fn constructor(_erc20: ContractAddress) {
        _token::write(_erc20);
    }

    #[external]
    fn list(nft_contract_address: ContractAddress, tokenId: u256, price: u128, expires_at: u128) {
        // nft owner must set_approval_for_all for this contract

        assert(
            _erc721_dispatcher(
                nft_contract_address
            ).is_approved_for_all(get_caller_address(), get_contract_address()),
            'must be approved for all'
        );

        _listings::write(
            (nft_contract_address, tokenId),
            Listing { seller: get_caller_address(), price: price, expires_at: expires_at }
        );
    }

    #[view]
    fn get_listing(nft_contract_address: ContractAddress, tokenId: u256) -> Listing {
        _listings::read((nft_contract_address, tokenId))
    }

    #[external]
    fn offer(
        nft_contract_address: ContractAddress, tokenId: u256, bid_amount: u128, expires_at: u128
    ) {
        assert(
            _erc20_dispatcher().allowance(
                get_caller_address(), get_contract_address()
            ) == BoundedU256::max(),
            'must be aproved for max amount'
        );
        _offers::write(
            (nft_contract_address, get_caller_address(), tokenId), Offer { bid_amount, expires_at }
        );
    }

    #[view]
    fn get_offer(
        nft_contract_address: ContractAddress, bidder: ContractAddress, tokenId: u256
    ) -> Offer {
        _offers::read((nft_contract_address, get_caller_address(), tokenId))
    }


    #[external]
    fn sendToken(to: ContractAddress, value: u256) {
        let approve_amount = _erc20_dispatcher().allowance(
            get_caller_address(), get_contract_address()
        );
        _erc20_dispatcher().transfer_from(get_caller_address(), to, value);
    }

    // #[external]
    // fn deposit(amount: u256) {
    //     let caller = get_caller_address();
    //     _balances::write(caller, _balances::read(caller) + amount);
    //     _erc20_dispatcher().transfer_from(caller, get_contract_address(), amount);
    // }

    // #[external]
    // fn withdraw(amount: u256) {
    //     let caller = get_caller_address();
    //     _balances::write(caller, _balances::read(caller) - amount);
    //     _erc20_dispatcher().transfer(caller, amount);
    // }

    // #[view]
    // fn get_user_balance(user: ContractAddress) -> u256 {
    //     _balances::read(user)
    // }

    #[inline(always)]
    fn _erc20_dispatcher() -> IERC20Dispatcher {
        IERC20Dispatcher { contract_address: _token::read() }
    }

    #[inline(always)]
    fn _erc721_dispatcher(_contract: ContractAddress) -> IERC721Dispatcher {
        IERC721Dispatcher { contract_address: _contract }
    }

    #[view]
    fn get_erc20_address() -> ContractAddress {
        _token::read()
    }
}
// _erc20.print();
// let thisContract = get_contract_address();
// thisContract.print();
// 'hello.cairo'.print();


