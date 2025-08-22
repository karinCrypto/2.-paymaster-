// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IEntryPoint {
    function depositTo(address account) external payable;
    function handleOps(bytes calldata ops, address payable beneficiary) external;
}

contract MinimalSmartAccount {
    address public owner;
    IEntryPoint public entryPoint;

    constructor(address _entryPoint, address _owner) {
        entryPoint = IEntryPoint(_entryPoint);
        owner = _owner;
    }

    modifier onlyEntryPoint() {
        require(msg.sender == address(entryPoint), "Not from EntryPoint");
        _;
    }

    function validateUserOp(
        bytes calldata userOp,
        bytes32,
        uint256
    ) external view onlyEntryPoint returns (uint256) {
        require(owner != address(0), "No owner set");
        return 0;
    }

    function execute(address dest, uint256 value, bytes calldata func)
        external
        onlyEntryPoint
    {
        (bool success, ) = dest.call{value: value}(func);
        require(success, "Execution failed");
    }

    receive() external payable {}
}
