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
mod Marketplace {
    use starknet::get_caller_address;
    use super::IERC20DispatcherTrait;
    use super::IERC20Dispatcher;
    use super::IERC20LibraryDispatcher;
    use starknet::info::get_contract_address;
    use debug::PrintTrait;
    use starknet::ContractAddress;

    struct Storage {
        _token: ContractAddress,
        _total_supply: u256,
        _balances: LegacyMap<ContractAddress, u256>,
        //_listings[nft_contract_address][tokenId] = (SELLER,PRICE,EXPIRES_AT)
        _listings: LegacyMap<(ContractAddress, u256), (ContractAddress,u256,u256)>,
        //_offers[nft_contract_address][tokenId][bidder] = (bid_amount,expiresAt)
        _offers: LegacyMap<(ContractAddress,u256,ContractAddress),(u256,u256)>
    }

    #[constructor]
    fn constructor(_erc20: ContractAddress) {
        _token::write(_erc20);
    }

    #[external]
    fn add_listing(nft_contract_address: ContractAddress, tokenId: u256, price: u256, expiresAt: u256) {
        _listings::write((nft_contract_address, tokenId), value);
    }
    #[view]
    fn get_listing(nft_contract_address: ContractAddress, tokenId: u256) {
        _listings::read((nft_contract_address, tokenId));
    }

    #[external]
    fn sendToken(to: ContractAddress, value: u256) {
        let approve_amount = _erc20_dispatcher().allowance(
            get_caller_address(), get_contract_address()
        );
        approve_amount.print();
        _erc20_dispatcher().transfer_from(get_caller_address(), to, value);
    }

    #[external]
    fn deposit(amount: u256) {
        let caller = get_caller_address();
        _balances::write(caller, _balances::read(caller) + amount);
        _erc20_dispatcher().transfer_from(caller, get_contract_address(), amount);
    }

    #[external]
    fn withdraw(amount: u256) {
        let caller = get_caller_address();
        _balances::write(caller, _balances::read(caller) - amount);
        _erc20_dispatcher().transfer(caller, amount);
    }

    #[view]
    fn get_user_balance(user: ContractAddress) -> u256 {
        _balances::read(user)
    }

    #[inline(always)]
    fn _erc20_dispatcher() -> IERC20Dispatcher {
        IERC20Dispatcher { contract_address: _token::read() }
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


