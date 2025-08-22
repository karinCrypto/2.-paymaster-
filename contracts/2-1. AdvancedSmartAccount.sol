// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// OpenZeppelin 라이브러리에서 ECDSA 서명 검증 유틸 불러오기
// - recover() 함수로 서명에서 signer 주소를 복원 가능
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @notice EntryPoint 인터페이스 정의 (EIP-4337의 핵심 컨트랙트)
/// @dev 계정은 EntryPoint를 통해서만 UserOperation을 실행할 수 있음
interface IEntryPoint {
    /// @notice 특정 계정에 가스비(ETH)를 예치
    /// @dev 계정이 직접 충전할 수도 있고, Paymaster가 대신 충전할 수도 있음
    /// @param account 가스비를 충전할 대상 계정 주소
    function depositTo(address account) external payable;

    /// @notice 번들러(Bundler)가 UserOperation들을 모아서 EntryPoint에 제출할 때 실행
    /// @dev EntryPoint가 각 계정의 validateUserOp → execute 순서로 실행시킴
    /// @param ops 여러 UserOperation들이 직렬화된 데이터
    /// @param beneficiary 수수료를 받을 주소 (보통 번들러)
    function handleOps(bytes calldata ops, address payable beneficiary) external;
}

/// @title AdvancedSmartAccount
/// @notice EIP-4337 학습용 고급 스마트 계정
/// - ECDSA 서명 검증
/// - 멀티시그 오너쉽
/// - Paymaster 가스 대납 지원
contract AdvancedSmartAccount {
    using ECDSA for bytes32; // ECDSA 라이브러리를 bytes32 타입에 붙여 확장

    // ===== 상태 변수 =====
    address[] public owners;              // 오너 리스트
    mapping(address => bool) public isOwner; // 특정 주소가 오너인지 여부
    uint256 public requiredSignatures;    // 필요한 최소 서명 수
    IEntryPoint public entryPoint;        // EntryPoint 주소

    // ===== 생성자 =====
    /// @param _entryPoint EntryPoint 컨트랙트 주소
    /// @param _owners 계정 소유자 배열
    /// @param _required 최소 서명 필요 개수
    constructor(address _entryPoint, address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "At least 1 owner required");
        require(_required > 0 && _required <= _owners.length, "Invalid required number");

        entryPoint = IEntryPoint(_entryPoint);

        // 오너 배열 등록 + 중복 방지
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Duplicate owner");
            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredSignatures = _required;
    }

    // ===== 접근 제어 =====
    /// @notice EntryPoint에서만 호출 가능
    modifier onlyEntryPoint() {
        require(msg.sender == address(entryPoint), "Not from EntryPoint");
        _;
    }

    // ===== 핵심 함수 =====

    /// @notice UserOperation 검증 함수
    /// @dev EntryPoint가 UserOperation 실행 전 항상 호출
    /// - 오너들의 ECDSA 서명이 유효한지 확인
    /// - Paymaster 가스 대납이 필요한 경우 충전 처리
    /// @param userOpHash UserOperation을 해시한 값
    /// @param signatures 여러 오너들의 서명 배열
    /// @param missingFunds EntryPoint가 요구하는 가스비 보충액
    /// @return 항상 0 (EIP-4337 규격상 성공 시 0 반환)
    function validateUserOp(
        bytes32 userOpHash,
        bytes[] calldata signatures,
        uint256 missingFunds
    ) external payable onlyEntryPoint returns (uint256) {
        require(signatures.length >= requiredSignatures, "Not enough signatures");

        uint256 validCount = 0;
        address[] memory seen = new address[](signatures.length);

        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = userOpHash.toEthSignedMessageHash().recover(signatures[i]);
            if (isOwner[signer]) {
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

        // Paymaster 또는 계정 자체가 부족한 가스비를 EntryPoint에 송금
        if (missingFunds > 0) {
            (bool success, ) = payable(msg.sender).call{value: missingFunds}("");
            require(success, "Failed to pay missing funds");
        }

        return 0;
    }

    /// @notice 트랜잭션 실행 함수
    /// @dev EntryPoint가 검증된 UserOperation을 실행할 때 호출
    /// @param dest 호출 대상 주소
    /// @param value 보낼 ETH 값
    /// @param func 실행할 함수 데이터 (calldata)
    function execute(address dest, uint256 value, bytes calldata func)
        external
        onlyEntryPoint
    {
        (bool success, ) = dest.call{value: value}(func);
        require(success, "Execution failed");
    }

    // ===== 특수 함수 =====
    /// @notice ETH 입금 시 실행 (기본 수신 함수)
    receive() external payable {}

    /// @notice 정의되지 않은 함수 호출 시 실행
    fallback() external payable {}
}
