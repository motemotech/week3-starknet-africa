%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from starkware.cairo.common.math import (assert_not_equal, assert_not_zero, assert_le)

from openzeppelin.token.erc20.IERC20 import IERC20

const ETHEREUM_ADDRESS = 2087021424722619777119509474943472645767659996348769578120564519014510906823;
const ETHEREUM_AMOUNT = 1000000000000000;

@storage_var
func token_address() -> (address: felt) {
}

@storage_var
func admin_address() -> (address: felt) {
}

@storage_var
func registered_address(address: felt) -> (isRegistered: felt) {
}

@storage_var
func claimed_address(address: felt) -> (isClaimed: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _admin_address: felt, _token_address: felt
) {
    admin_address.write(_admin_address);
    token_address.write(_token_address);
    return ();
}

@external
func register{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller) = get_caller_address();
    let (this_contract) = get_contract_address();

    let (approvedEther) = IERC20.allowance(contract_address=ETHEREUM_ADDRESS, owner=caller, spender=this_contract);
    with_attr error_message("You need to aprove more than 0.001 ether before register"){
        assert_le(approvedEther.low, ETHEREUM_AMOUNT);
    }

    IERC20.transferFrom(contract_address=ETHEREUM_ADDRESS, sender=caller, recipient=this_contract, amount=Uint256(low=ETHEREUM_AMOUNT, high=0));
    registered_address.write(caller, 1);
    return ();
}

@external
func claim{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (caller) = get_caller_address();

    let (isRegistered) = registered_address.read(caller);
    with_attr error_message("You must be registered") {
        assert_not_zero(isRegistered);
    }

    let (isClaimed) = claimed_address.read(caller);
    with_attr error_message("You have already claimed") {
        assert_not_equal(isClaimed, 1);
    }

    let (starkTokenAddress) = token_address.read();
    let (admin) = admin_address.read();
    let (this_contract) = get_contract_address();
    let (approvedStarkToken) = IERC20.allowance(contract_address=starkTokenAddress, owner=admin, spender=this_contract);
    with_attr error_message("Pls wait until admin give approval for StarknetAfrica token") {
        assert_le(approvedStarkToken.low, 20);
    }

    claimed_address.write(caller, 1);
    IERC20.transferFrom(contract_address=starkTokenAddress, sender=this_contract, recipient=caller, amount=Uint256(low=20, high=0));
    return ();
}
