// scripts/deploy.js
// Hardhat ESM 환경일 경우 → hardhat.config.mjs 에서 "module" 설정 필요
import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with:", deployer.address);

  // EntryPoint는 여기선 mock 주소 (실습용) 사용
  const entryPointAddress = deployer.address; // 임시
  const ownerAddress = deployer.address;

  const MinimalSmartAccount = await ethers.getContractFactory("MinimalSmartAccount");
  const account = await MinimalSmartAccount.deploy(entryPointAddress, ownerAddress);

  await account.waitForDeployment();

  console.log("MinimalSmartAccount deployed to:", await account.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
