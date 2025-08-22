// 주석 버전 입니다. 이해가 어려우신분은
//문법 설명 + 기능 설명을 같이 달아서 Solidity 문법 공부 + 4337 이해를 동시에 할 수 있게 준비했어요.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * AdvancedSmartAccount (학습용 예제)
 * - ECDSA 서명 검증
 * - Paymaster 지원
 * - 멀티시그 오너쉽
 */

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IEntryPoint {
    function depositTo(address account) external payable;
    function handleOps(bytes calldata ops, address payable beneficiary) external;
}

/// @title AdvancedSmartAccount
/// @notice EIP-4337 Account Abstraction + 실무적 보강 요소들
contract AdvancedSmartAccount {
    using ECDSA for bytes32;

    /**************************************************************
     * 상태 변수
     **************************************************************/
    address[] public owners;            // 멀티시그 오너 목록
    mapping(address => bool) public isOwner;
    uint256 public requiredSignatures;  // 최소 승인 개수

    IEntryPoint public entryPoint;

    /**************************************************************
     * 생성자
     **************************************************************/
    constructor(address _entryPoint, address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "At least 1 owner required");
        require(_required > 0 && _required <= _owners.length, "Invalid required number");

        entryPoint = IEntryPoint(_entryPoint);

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Duplicate owner");
            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredSignatures = _required;
    }

    modifier onlyEntryPoint() {
        require(msg.sender == address(entryPoint), "Not from EntryPoint");
        _;
    }

    /**************************************************************
     * validateUserOp
     * - 다중 서명 검증 (ECDSA)
     **************************************************************/
    function validateUserOp(
        bytes32 userOpHash,
        bytes[] calldata signatures, // 여러 서명 전달
        uint256 missingFunds
    ) external payable onlyEntryPoint returns (uint256) {
        require(signatures.length >= requiredSignatures, "Not enough signatures");

        uint256 validCount = 0;
        address[] memory seen = new address[](signatures.length);

        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = userOpHash.toEthSignedMessageHash().recover(signatures[i]);
            if (isOwner[signer]) {
                // 중복 방지
                bool duplicate = false;
                for (uint256 j = 0; j < validCount; j++) {
                    if (seen[j] == signer) {
                        duplicate = true;
                        break;
                    }
                }
                if (!duplicate) {
                    seen[validCount] = signer;
                    validCount++;
                }
            }
        }

        require(validCount >= requiredSignatures, "Not enough valid signatures");

        // Paymaster가 가스비를 대납해주는 경우 missingFunds > 0
        if (missingFunds > 0) {
            (bool success, ) = payable(msg.sender).call{value: missingFunds}("");
            require(success, "Failed to pay missing funds");
        }

        return 0; // 검증 성공
    }

    /**************************************************************
     * execute - 트랜잭션 실행
     **************************************************************/
    function execute(address dest, uint256 value, bytes calldata func)
        external
        onlyEntryPoint
    {
        (bool success, ) = dest.call{value: value}(func);
        require(success, "Execution failed");
    }

    /**************************************************************
     * 입출금 처리
     **************************************************************/
    receive() external payable {}
    fallback() external payable {}
}
