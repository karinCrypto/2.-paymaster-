# MinimalSmartAccount ⚡️

이 레포지토리는 **EIP-4337(Account Abstraction)** 학습을 위한 최소 스마트 계정 컨트랙트 예제입니다.  
EOA 대신 컨트랙트 계정이 **UserOperation**을 통해 트랜잭션을 실행하는 구조를 간단히 구현했습니다.  

---

## 📌 주요 개념
- **EntryPoint**: 번들러가 UserOperation을 모아 실행하는 중심 컨트랙트  
- **Smart Account**: EOA처럼 직접 서명하지 않고, EntryPoint가 호출해주는 컨트랙트 계정  
- **validateUserOp**: EntryPoint가 UserOperation을 검증할 때 호출  
- **execute**: 실제 트랜잭션을 실행하는 함수  

---

## 📂 파일
- `MinimalSmartAccount.sol` → 단일 오너 기반 스마트 계정 구현 (학습용)
  - `constructor` → EntryPoint, owner 설정
  - `validateUserOp` → UserOperation 검증 (단순 owner 체크)
  - `execute` → 트랜잭션 실행
  - `receive()` → ETH 입금 처리

---

## 🚀 학습 포인트
- Solidity 기본 문법 (`struct`, `mapping`, `modifier`, `require`)  
- 저수준 호출 (`call`)  
- EIP-4337 흐름: **UserOperation → EntryPoint → Smart Account → 실행**

---

## ⚠️ 주의
- 이 코드는 **학습용 최소 구현**입니다.  
- 실제 서비스에서는 반드시 **ECDSA 서명 검증, 멀티시그, 페이마스터 로직** 등이 필요합니다.  

---

## 📖 참고
- [EIP-4337 설명](https://eips.ethereum.org/EIPS/eip-4337)  
- [account-abstraction repo](https://github.com/eth-infinitism/account-abstraction)  

