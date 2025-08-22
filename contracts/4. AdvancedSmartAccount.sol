// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// OpenZeppelin ECDSA 라이브러리
// - 서명 검증에 필요한 recover(), toEthSignedMessageHash() 제공
// - Hardhat에서는 npm 설치(@openzeppelin/contracts)
// - Remix에서는 GitHub URL import 사용
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.9/contracts/utils/cryptography/ECDSA.sol";

/// @notice EntryPoint 인터페이스 (EIP-4337 핵심 컨트랙트)
/// - depositTo: 스마트 계정이 가스비(ETH)를 충전할 때 사용
/// - handleOps: 번들러(Bundler)가 UserOperation들을 모아서 실행할 때 사용
interface IEntryPoint {
    function depositTo(address account) external payable;
    function handleOps(bytes calldata ops, address payable beneficiary) external;
}

/// @title AdvancedSmartAccount
/// @notice EIP-4337 학습용 스마트 계정
/// - 단일 오너 서명 기반 검증
/// - EntryPoint 통해 UserOperation 실행
/// - Paymaster 가스 대납 처리 지원
contract AdvancedSmartAccount {
    using ECDSA for bytes32; // bytes32에 ECDSA 함수 확장 (recover 등 사용 가능)

    // ===== 상태 변수 =====
    address public owner;        // 계정 소유자
    IEntryPoint public entryPoint; // EntryPoint 컨트랙트 주소

    // ===== 생성자 =====
    /// @param _entryPoint EntryPoint 컨트랙트 주소
    /// @param _owner 계정 오너 주소
    constructor(address _entryPoint, address _owner) {
        require(_owner != address(0), "Invalid owner"); // 0번 주소 방지
        owner = _owner;                                 // 오너 등록
        entryPoint = IEntryPoint(_entryPoint);          // EntryPoint 등록
    }

    // ===== 접근 제어 =====
    /// @notice EntryPoint에서만 호출 가능
    modifier onlyEntryPoint() {
        require(msg.sender == address(entryPoint), "Not from EntryPoint");
        _;
    }

    // ===== 핵심 함수 =====

    /// @notice UserOperation 검증 함수
    /// @dev EntryPoint가 번들 처리 전에 호출
    /// - 오너의 서명 확인
    /// - 부족한 가스비 충전
    /// @param userOpHash keccak256으로 해싱된 UserOperation (bytes32)
    /// @param signature 오너의 서명
    /// @param missingFunds EntryPoint가 요구하는 부족한 가스비
    /// @return 항상 0 (성공 시)
    function validateUserOp(
        bytes32 userOpHash,
        bytes calldata signature,
        uint256 missingFunds
    ) external payable onlyEntryPoint returns (uint256) {
        // 1. 서명 복구 (msg.sender가 아닌, 실제 오너가 맞는지 확인)
        address signer = userOpHash.toEthSignedMessageHash().recover(signature);
        require(signer == owner, "Invalid signature");

        // 2. 부족한 가스비가 있으면 EntryPoint에 송금
        if (missingFunds > 0) {
            (bool success, ) = payable(msg.sender).call{value: missingFunds}("");
            require(success, "Failed to pay missing funds");
        }

        // 3. 검증 성공 → 0 반환
        return 0;
    }

    /// @notice 트랜잭션 실행 함수
    /// @dev EntryPoint가 validateUserOp 통과 후 호출
    /// @param dest 호출할 대상 주소
    /// @param value 전송할 ETH 값
    /// @param func 실행할 함수 데이터 (calldata)
    function execute(address dest, uint256 value, bytes calldata func)
        external
        onlyEntryPoint
    {
        (bool success, ) = dest.call{value: value}(func); // 로우레벨 호출
        require(success, "Execution failed");
    }

    // ===== 특수 함수 =====
    /// @notice ETH 입금 처리 함수
    receive() external payable {}

    /// @notice 정의되지 않은 함수 호출 시 실행
    fallback() external payable {}
}
