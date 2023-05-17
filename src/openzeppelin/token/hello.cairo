use starknet::ContractAddress;

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

#[contract]
mod HelloStarknet {
    use starknet::get_caller_address;
    use super::IERC20DispatcherTrait;
    use super::IERC20Dispatcher;
    use super::IERC20LibraryDispatcher;
    use starknet::info::get_contract_address;
    use debug::PrintTrait;
    use starknet::ContractAddress;

    struct Storage {
        value: u8,
        name: felt252,
        erc20Contract: ContractAddress,
        names: LegacyMap::<ContractAddress, felt252>,
    }

    #[constructor]
    fn constructor(_name: felt252, _erc20: ContractAddress) {
        name::write(_name);
        erc20Contract::write(_erc20);
    }

    #[external]
    fn setEnsName(_name: felt252) {
        let caller = get_caller_address();
        names::write(caller, _name);
    }

    #[view]
    fn getEnsName() -> felt252 {
        let caller = get_caller_address();
        names::read(caller)
    }

    #[external]
    fn sendToken(to: ContractAddress, value: u256) {
        let caller = get_caller_address();

        erc20Contract::read().print();
        IERC20Dispatcher {
            contract_address: erc20Contract::read()
        }.transfer_from(caller, to, value);
    }

    #[event]
    fn Hello(from: ContractAddress, value: felt252) {}

    #[external]
    fn say_hello(message: felt252) {
        let caller = get_caller_address();
        Hello(caller, message);
    }

    #[external]
    fn save_value(_value: u8) {
        value::write(_value);
    }

    #[view]
    fn get_value() -> u8 {
        value::read()
    }

    #[external]
    fn set_name(_name: felt252) {
        name::write(_name);
    }

    #[view]
    fn get_name() -> felt252 {
        name::read()
    }
    #[view]
    fn get_erc20_address() -> ContractAddress {
        erc20Contract::read()
    }
}
// _erc20.print();
// let thisContract = get_contract_address();
// thisContract.print();
// 'hello.cairo'.print();


