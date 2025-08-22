# Smart Accounts with EIP-4337 ⚡️

이 레포지토리는 **EIP-4337(Account Abstraction)** 을 학습하기 위한 두 가지 스마트 계정 컨트랙트를 포함합니다.  
- `MinimalSmartAccount.sol` → 최소 구현 (기본 뼈대)  
- `AdvancedSmartAccount.sol` → 실무 개념 반영 (ECDSA, Paymaster, 멀티시그)  

---

## 📂 Contracts

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

## ⚙️ 설치 방법

### 1. Hardhat 프로젝트 초기화
npm init -y
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox


2. OpenZeppelin (Advanced 버전에 필요)
npm install @openzeppelin/contracts


## ⚙️ 실행 방법 (VSCode / Hardhat)

컴파일
npx hardhat compile


테스트 실행
npx hardhat test

로컬 배포 (선택)
npx hardhat node      # 터미널1: 로컬 네트워크 실행
npx hardhat run scripts/deploy.js --network localhost   # 터미널2: 배포

📖 참고

[EIP-4337 설명](https://eips.ethereum.org/EIPS/eip-4337)
[account-abstraction repo](https://github.com/eth-infinitism/account-abstraction)
[OpenZeppelin ECDSA](https://docs.openzeppelin.com/contracts/4.x/api/utils#ECDSA)
