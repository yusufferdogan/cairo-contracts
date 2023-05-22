use openzeppelin::marketplace::marketplace::Marketplace;
use openzeppelin::marketplace::marketplace::IERC20DispatcherTrait;
use openzeppelin::marketplace::marketplace::IERC20Dispatcher;
use openzeppelin::marketplace::marketplace::IERC20LibraryDispatcher;
use openzeppelin::token::erc20::ERC20;

use starknet::contract_address_const;
use starknet::ContractAddress;
use starknet::testing::set_caller_address;
use starknet::testing::set_contract_address;
use starknet::info::get_contract_address;
use starknet::syscalls::deploy_syscall;
use starknet::class_hash::Felt252TryIntoClassHash;
use starknet::contract_address::ContractAddressIntoFelt252;

use integer::u256;
use integer::u256_from_felt252;
use debug::PrintTrait;

use traits::Into;
use traits::TryInto;
use option::OptionTrait;
use result::ResultTrait;
use array::ArrayTrait;

#[abi]
trait IMarketplace {
    fn sendToken(to: ContractAddress, value: u256);
    fn get_erc20_address() -> ContractAddress;
    fn deposit(amount: u256);
    fn get_user_balance(user: ContractAddress) -> u256;
    fn withdraw(amount: u256);
    fn add_listing(nft_contract_address: ContractAddress, tokenId: u256, value: u256);
    fn get_listing(nft_contract_address: ContractAddress, tokenId: u256);
}

const NAME: felt252 = 111;
const SYMBOL: felt252 = 222;

fn setup() -> (ContractAddress, ContractAddress) {
    let user1 = contract_address_const::<0x123456789>();

    let mut calldata = ArrayTrait::new();
    let name = 'TOKEN_A';
    let symbol = 'TKNA';
    let initial_supply_low = 100;
    let initial_supply_high = 0;
    let recipient: felt252 = user1.into();
    calldata.append(name);
    calldata.append(symbol);
    calldata.append(initial_supply_low);
    calldata.append(initial_supply_high);
    calldata.append(recipient);

    let (token_address, _) = deploy_syscall(
        ERC20::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    ).unwrap();

    let mut calldata = ArrayTrait::new();
    calldata.append(token_address.into());
    let (hello_address, _) = deploy_syscall(
        Marketplace::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    ).unwrap();

    (token_address, hello_address)
}

#[test]
#[available_gas(2000000)]
fn test_erc20_constructor() {
    let initial_supply: u256 = u256_from_felt252(2000);
    let account: ContractAddress = contract_address_const::<1>();
    let decimals: u8 = 18_u8;

    ERC20::constructor(NAME, SYMBOL, initial_supply, account);

    let owner_balance: u256 = ERC20::balance_of(account);
    assert(owner_balance == initial_supply, 'Should eq inital_supply');
}

#[test]
#[available_gas(2000000)]
fn test_send_token() {
    let (token_address, hello_address) = setup();
    let token = IERC20Dispatcher { contract_address: token_address };
    let helloContract = IMarketplaceDispatcher { contract_address: hello_address };

    let user1 = contract_address_const::<0x123456789>();

    let to: ContractAddress = contract_address_const::<963>();
    let amount: u256 = 50.into();

    assert(helloContract.get_erc20_address() == token_address, 'balance');

    set_contract_address(user1); // `caller_address` in contract will return
    token.approve(hello_address, amount);
    helloContract.sendToken(to, amount);

    assert(token.balance_of(to) == amount, 'balance');
}

#[test]
#[available_gas(2000000)]
fn test_deposit() {
    let (token_address, hello_address) = setup();
    let token = IERC20Dispatcher { contract_address: token_address };
    let helloContract = IMarketplaceDispatcher { contract_address: hello_address };

    let user1 = contract_address_const::<0x123456789>();

    let to: ContractAddress = contract_address_const::<963>();
    let amount: u256 = 50.into();

    set_contract_address(user1); // `caller_address` in contract will return
    // `user1` instead of `0`.
    token.approve(hello_address, amount);
    helloContract.deposit(amount);
    assert(token.balance_of(hello_address) == amount, 'balance_of');
    assert(helloContract.get_user_balance(user1) == amount, 'get_user_balance');
}
#[test]
#[available_gas(2000000)]
fn test_withdraw() {
    let (token_address, hello_address) = setup();
    let token = IERC20Dispatcher { contract_address: token_address };
    let helloContract = IMarketplaceDispatcher { contract_address: hello_address };

    let user1 = contract_address_const::<0x123456789>();

    let to: ContractAddress = contract_address_const::<963>();
    let amount: u256 = 50.into();

    set_contract_address(user1); // `caller_address` in contract will return
    // `user1` instead of `0`.
    token.approve(hello_address, amount);
    helloContract.deposit(amount);
    assert(token.balance_of(hello_address) == amount, 'balance_of');
    assert(helloContract.get_user_balance(user1) == amount, 'get_user_balance');

    helloContract.withdraw(amount);
    assert(token.balance_of(hello_address) == 0.into(), 'balance_of');
    assert(helloContract.get_user_balance(user1) == 0.into(), 'get_user_balance');
}
#[test]
#[available_gas(2000000)]
fn test_listing() {
    let (token_address, hello_address) = setup();
    let token = IERC20Dispatcher { contract_address: token_address };
    let helloContract = IMarketplaceDispatcher { contract_address: hello_address };

    let user1 = contract_address_const::<0x123456789>();
    let to: ContractAddress = contract_address_const::<963>();
    let amount: u256 = 50.into();

    helloContract.add_listing(user1,1.into(),1.into());
}