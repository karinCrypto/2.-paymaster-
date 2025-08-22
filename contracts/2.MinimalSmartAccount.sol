// 주석 버전 입니다. 이해가 어려우신분은
//문법 설명 + 기능 설명을 같이 달아서 Solidity 문법 공부 + 4337 이해를 동시에 할 수 있게 준비했어요.


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; 
// Solidity 버전 지정 (0.8.20 이상 사용)
// ^ → "이 버전 이상, 다음 메이저 버전 미만" 이라는 의미
// 0.8.x 버전대는 산술 오버플로우 자동 체크 기능이 내장됨


/**************************************************************
 *  EIP-4337 (Account Abstraction) 학습용 최소 스마트 계정
 * 
 *  핵심 개념:
 *  - EntryPoint 컨트랙트가 모든 UserOperation을 모아 처리
 *  - 이 스마트 계정은 EntryPoint로부터 호출받아 트랜잭션 실행
 *  - "EOA(Externally Owned Account)" 대신 "스마트 월렛"이 되는 구조
 **************************************************************/

/// @notice EntryPoint 컨트랙트와 상호작용하기 위한 최소 인터페이스
/// @dev 여기서는 depositTo(), handleOps() 두 함수만 정의
interface IEntryPoint {
    function depositTo(address account) external payable;
    function handleOps(
        bytes calldata ops,
        address payable beneficiary
    ) external;
}

/// @title MinimalSmartAccount
/// @notice 단일 오너(owner)만 트랜잭션을 실행할 수 있는 최소 계정
/// @dev 학습용: 실무에서는 서명 검증, 멀티시그, 페이마스터 로직 필요
contract MinimalSmartAccount {
    /**************************************************************
     * 상태 변수 (State Variables)
     **************************************************************/
    address public owner;        // 이 스마트 계정의 소유자 (EOA 주소)
    IEntryPoint public entryPoint; // EntryPoint 컨트랙트 주소 (EIP-4337 핵심)

    /**************************************************************
     * 생성자 (constructor)
     * - 컨트랙트 배포 시 최초 실행
     * - EntryPoint 주소와 Owner 주소를 세팅
     **************************************************************/
    constructor(address _entryPoint, address _owner) {
        entryPoint = IEntryPoint(_entryPoint); // 인터페이스 형변환
        owner = _owner;
    }

    /**************************************************************
     * Modifier
     * - 함수 실행 전 특정 조건을 검사하는 코드 블록
     * - 여기서는 "EntryPoint만 호출할 수 있도록 제한"
     **************************************************************/
    modifier onlyEntryPoint() {
        require(msg.sender == address(entryPoint), "Not from EntryPoint");
        _; // 이 밑의 본문 실행 허용
    }

    /**************************************************************
     * validateUserOp
     * - EIP-4337 규격에 맞게 "UserOperation 검증"을 수행하는 함수
     * - EntryPoint가 호출
     * - 반환값: uint256 (0이면 성공, 그 외는 실패)
     *
     * 매개변수:
     * - userOp: UserOperation 데이터 (실제론 struct지만 여기선 bytes)
     * - userOpHash: UserOperation 해시값
     * - missingFunds: 계정에 입금돼야 하는 가스비 부족분
     **************************************************************/
    function validateUserOp(
        bytes calldata userOp,
        bytes32 /* userOpHash */,
        uint256 /* missingFunds */
    ) external view onlyEntryPoint returns (uint256) {
        // 여기서는 단순히 "owner가 존재하는지만 확인"
        // (실무에서는 ECDSA 서명 검증 필수!)
        require(owner != address(0), "No owner set");

        // 0을 반환하면 "검증 성공"
        return 0;
    }

    /**************************************************************
     * execute
     * - 실제 트랜잭션을 실행하는 함수
     * - EntryPoint가 호출
     *
     * 매개변수:
     * - dest: 실행할 컨트랙트 주소
     * - value: 전송할 ETH 값 (wei 단위)
     * - func: 실행할 함수의 call data (ex. encodeWithSignature로 생성)
     **************************************************************/
    function execute(address dest, uint256 value, bytes calldata func)
        external
        onlyEntryPoint
    {
        // low-level call: 다른 컨트랙트 함수 실행
        (bool success, ) = dest.call{value: value}(func);

        // 실행 실패 시 전체 revert
        require(success, "Execution failed");
    }

    /**************************************************************
     * receive() 함수
     * - 컨트랙트가 ETH를 직접 받을 때 호출됨
     * - "payable" 키워드 없으면 ETH 수신 불가
     **************************************************************/
    receive() external payable {}
}
