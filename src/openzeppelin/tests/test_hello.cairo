use openzeppelin::token::hello::HelloStarknet;
use starknet::contract_address_const;
use starknet::ContractAddress;
use starknet::testing::set_caller_address;
use starknet::testing::set_contract_address;
use starknet::info::get_contract_address;
use starknet::contract_address::ContractAddressIntoFelt252;
use integer::u256;
use integer::u256_from_felt252;
use openzeppelin::token::erc20::ERC20;
use debug::PrintTrait;
use starknet::syscalls::deploy_syscall;
use starknet::class_hash::Felt252TryIntoClassHash;
use traits::Into;
use traits::TryInto;
use option::OptionTrait;
use result::ResultTrait;
use array::ArrayTrait;
const NAME: felt252 = 111;
const SYMBOL: felt252 = 222;
fn setup_deploy_erc20() -> (ContractAddress, ContractAddress) {
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
        ERC20::CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    ).unwrap();

    let mut calldata = ArrayTrait::<felt252>::new();
    calldata.append(token_address.into());
    let (vault_address, _) = deploy_syscall(
        HelloStarknet::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    ).unwrap();

    (token_address, vault_address)
}
fn setupERC20() -> (ContractAddress, u256, ContractAddress) {
    let initial_supply: u256 = u256_from_felt252(2000);
    let account: ContractAddress = contract_address_const::<1>();
    let erc20: ContractAddress = contract_address_const::<777>();
    let decimals: u8 = 18_u8;

    // Set account as default caller
    set_caller_address(account);
    set_contract_address(erc20);

    ERC20::constructor(NAME, SYMBOL, initial_supply, account);
    assert(ERC20::total_supply() == initial_supply, 'Should eq inital_supply');
    assert(ERC20::name() == NAME, 'Name should be NAME');
    assert(ERC20::symbol() == SYMBOL, 'Symbol should be SYMBOL');
    assert(ERC20::decimals() == decimals, 'Decimals should be 18');
    (account, initial_supply, erc20)
}
const HELLO_NAME: felt252 = 'yusuf';
fn setup() -> ContractAddress {
    let (owner, supply, erc20) = setupERC20();
    let helloContractAddress: ContractAddress = contract_address_const::<9>();

    set_contract_address(erc20);
    HelloStarknet::constructor(HELLO_NAME, erc20);

    assert(HelloStarknet::get_name() == HELLO_NAME, 'NAME MUST BE CORRECT');
    assert(HelloStarknet::get_erc20_address() == erc20, 'NAME MUST BE CORRECT');

    let amount: u256 = u256_from_felt252(1000);
    let success: bool = ERC20::approve(helloContractAddress, amount);
    assert(success, 'Should return true');
    owner
}
#[test]
#[available_gas(2000000)]
fn test_constructor() {
    let value = 15_u8;
    setup();
    HelloStarknet::save_value(value);
    assert(value == HelloStarknet::get_value(), 'value must be equal to 123');
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

    assert(ERC20::total_supply() == initial_supply, 'Should eq inital_supply');
    assert(ERC20::name() == NAME, 'Name should be NAME');
    assert(ERC20::symbol() == SYMBOL, 'Symbol should be SYMBOL');
    assert(ERC20::decimals() == decimals, 'Decimals should be 18');
}
#[test]
#[available_gas(2000000)]
fn test_save_value() {
    let value = 15_u8;
    setup();
    HelloStarknet::save_value(value);
    assert(value == HelloStarknet::get_value(), 'value must be equal to 123');
}

#[test]
#[available_gas(2000000)]
fn test_get_name() {
    setup();
    assert(HELLO_NAME == HelloStarknet::get_name(), 'name is correct');
}

#[test]
#[available_gas(2000000)]
fn test_ens_name() {
    let owner = setup();
    HelloStarknet::setEnsName('yusuf');
    let ensName = HelloStarknet::getEnsName();
    assert(ensName == 'yusuf', 'name is correct');
}
#[test]
#[available_gas(2000000)]
fn test_send_token() {
    let owner = setup();
    let to: ContractAddress = contract_address_const::<963>();
    let amount: u256 = u256_from_felt252(10);

    set_caller_address(owner);
    HelloStarknet::sendToken(to, amount);
    assert(ERC20::balance_of(to) == amount, 'balance');
}

