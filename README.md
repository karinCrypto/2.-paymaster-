# Smart Accounts with EIP-4337 ⚡️
karin.blockdev@gmail.com

이 레포지토리는 **EIP-4337(Account Abstraction)** 을 학습하기 위한 두 가지 스마트 계정 컨트랙트를 포함합니다.  
- `MinimalSmartAccount.sol` → 최소 구현 (기본 뼈대)  
- `AdvancedSmartAccount.sol` → 실무 개념 반영 (ECDSA, Paymaster, 멀티시그)  
- 순서: UserOp → Alt-Mempool → EntryPoint.sol → MyAccount.sol → Paymaster.sol → 블록체인
- 직접 배포/실행 실습 → Node.js + Hardhat(or Foundry) + MetaMask + Sepolia ETH faucet → 전부 필요
---

# MinimalSmartAccount & AdvancedSmartAccount 실습

## ⚙️ 사전 준비
- **Node.js**: Hardhat, Foundry 같은 개발 툴 실행 환경
- **Hardhat (또는 Foundry)**: Solidity 컴파일/배포/테스트 프레임워크
- **MetaMask**: 테스트넷 계정 관리 (Sepolia 네트워크 추가)
- **Sepolia ETH faucet**: 테스트용 ETH 받기

<순서 정리>
Node.js 설치 → Hardhat 프로젝트 초기화

라이브러리 설치 (Hardhat, OpenZeppelin, Account Abstraction)

컨트랙트 작성 → 컴파일 → 테스트

로컬 배포 or Sepolia 테스트넷 배포

MetaMask/Etherscan에서 컨트랙트 확인


## ⚙️ 설치 방법

### 1. Hardhat 프로젝트 초기화 및 설정
```bash
npm init -y
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npm install @openzeppelin/contracts
npm install @account-abstraction/contracts

npx hardhat
```
### 2. OpenZeppelin (Advanced 버전 필요)
```bash
npm install @openzeppelin/contracts
```
### 3. Account Abstraction 관련 라이브러리
```bash
테스트넷 배포 (Sepolia)
npx hardhat run scripts/deploy.js --network sepolia
```

## ⚙️ 실행 방법 (VSCode / Hardhat)
### 1. 컴파일
```bash
npx hardhat compile
```
### 2. 테스트 실행
```bash
npx hardhat test
```
### 3. 로컬 배포 (선택)
```bash
# 터미널 1: 로컬 네트워크 실행
npx hardhat node

# 터미널 2: 로컬 네트워크에 배포
npx hardhat run scripts/deploy.js --network localhost
```

### 4. 테스트넷 배포 (Sepolia)
```bash
npx hardhat run scripts/deploy.js --network sepolia
```

### 4. 로컬 배포 테스트
```bash
npx hardhat node    # 터미널 1
npx hardhat run scripts/deploy.js --network localhost   # 터미널 2
```
### 5. Sepolia 네트워크 배포 (hardhat.config.js 수정)
```bash
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.20",
  networks: {
    sepolia: {
      url: "https://sepolia.infura.io/v3/<YOUR_INFURA_KEY>",
      accounts: ["0x<YOUR_PRIVATE_KEY>"],
    },
  },
};
```
```bash
npx hardhat run scripts/deploy.js --network sepolia
```

### 1. MinimalSmartAccount.sol
4337의 최소 개념을 담은 계정 컨트랙트

- **핵심 기능**
  - EntryPoint와 연결 (`IEntryPoint`)
  - `validateUserOp()` → UserOperation 검증 (owner 존재 여부만 체크)
  - `execute()` → EntryPoint가 호출하는 트랜잭션 실행
  - `receive()` → ETH 입금 처리  

- **학습 포인트**
  - Solidity 기본 문법 (constructor, state variables, modifier, require)
  - 데이터 위치 (`calldata`)
  - 접근 제어 (`onlyEntryPoint`)
  - 저수준 호출 (`dest.call{value: value}(func)`)

---

### 2. AdvancedSmartAccount.sol
실무에서 요구되는 주요 기능을 추가한 확장 버전

- **추가된 기능**
  - **ECDSA 서명 검증** → OpenZeppelin 라이브러리 활용
  - **멀티시그 오너쉽** → 여러 소유자, `requiredSignatures` 이상 서명 필요
  - **Paymaster 지원** → 가스비 대납 로직 (`missingFunds`)
  - `execute()`로 트랜잭션 실행
  - `receive()` & `fallback()` 으로 ETH 입금 및 예외 호출 처리  

- **학습 포인트**
  - 인터페이스(`IEntryPoint`)와 외부 라이브러리(`import`)
  - 배열/매핑 + 제어문(for/if)
  - 에러 처리(require)
  - 멀티시그 로직 (중복 방지, 유효 서명 카운트)
  - Paymaster 구조 반영

---

# UserOperation Overview

`UserOperation` is a struct that describes a transaction-like object sent on behalf of a user.
It is deliberately not called a "transaction" to avoid confusion.

---

## Fields

Similar to a transaction, it contains:

* `to`
* `calldata`
* `maxFeePerGas`
* `maxPriorityFeePerGas`
* `nonce`
* `signature` *(defined by the account implementation, not the protocol)*

---

## Components

* **Sender**
  Smart contract account that initiates the `UserOperation`.

* **EntryPoint**
  Singleton contract that executes bundled `UserOperations`.
  Bundlers must whitelist the supported `EntryPoint`.

* **Bundler**
  Node that collects and submits valid `UserOperations` via `entryPoint.handleOps()`.

  * May also act as a block builder.
  * If not, it must work with builder infra such as [EIP-7732](https://eips.ethereum.org/EIPS/eip-7732).
  * Optional experimental RPC: [ERC-7796](https://eips.ethereum.org/EIPS/eip-7796) `eth_sendRawTransactionConditional`.

* **Paymaster**
  Contract that agrees to pay for gas on behalf of the sender.

* **Factory**
  Helper contract for deploying new accounts if needed.

* **Aggregator**
  Approver contract for shared verification of multiple `UserOperations`.
  Defined in [ERC-7766](https://eips.ethereum.org/EIPS/eip-7766).

---

## Mempool

* **Canonical mempool**
  Decentralized, permissionless P2P network exchanging valid `UserOperations` that comply with [ERC-7562](https://eips.ethereum.org/EIPS/eip-7562).

* **Alternative mempool**
  P2P network that applies different validation rules.

---

## Deposit

Ether (or L2 native token) transferred by the account or `Paymaster` to the `EntryPoint`
to cover future gas costs.

---

## Reference

* [ERC-4337: Account Abstraction](https://eips.ethereum.org/EIPS/eip-4337)
* [ERC-7562: Canonical mempool](https://eips.ethereum.org/EIPS/eip-7562)
* [ERC-7766: Aggregators](https://eips.ethereum.org/EIPS/eip-7766)
* [ERC-7796: Conditional Raw Tx RPC](https://eips.ethereum.org/EIPS/eip-7796)


---

## 📌 Solidity 문법 요약

두 컨트랙트에서 다루는 주요 문법:

- `pragma solidity ^0.8.20;` → 버전 지정  
- `contract, interface` → 컨트랙트 구조 정의  
- `constructor` → 생성자  
- `state variables` → 상태 변수 (storage)  
- `modifier` → 재사용 조건 로직  
- `require` → 조건 체크 + revert  
- `view, external, payable` → 함수 속성  
- `calldata, memory` → 데이터 위치  
- `receive(), fallback()` → ETH 입금 처리  
- `low-level call` → `dest.call{value: value}(func)`  

---

📖 참고

[EIP-4337 설명](https://eips.ethereum.org/EIPS/eip-4337)
[account-abstraction repo](https://github.com/eth-infinitism/account-abstraction)
[OpenZeppelin ECDSA](https://docs.openzeppelin.com/contracts/4.x/api/utils#ECDSA)
