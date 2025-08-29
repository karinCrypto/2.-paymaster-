pragma solidity 0.8.20;
import "@account-abstraction/contracts/core/BasePaymaster.sol";
//계정 추상화용 스마트 계정 코드

contract MyPaymaster is BasePaymaster {
    constructor(IEntryPoint _entryPoint) BasePaymaster(_entryPoint) {}

    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32, uint256
    ) external view override returns (bytes memory, uint256) {
        require(userOp.sender != address(0), "Invalid sender");
        return ("", 0);
    }
}
