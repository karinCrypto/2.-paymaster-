import { expect } from "chai";
import { ethers } from "hardhat";

describe("MinimalSmartAccount", function () {
  let account, entryPoint, owner, other;

  beforeEach(async () => {
    [owner, other] = await ethers.getSigners();

    // 임시 EntryPoint mock (owner 주소를 EntryPoint처럼 사용)
    entryPoint = owner.address;

    const MinimalSmartAccount = await ethers.getContractFactory("MinimalSmartAccount");
    account = await MinimalSmartAccount.deploy(entryPoint, owner.address);
    await account.waitForDeployment();
  });

  it("should set the correct owner", async () => {
    expect(await account.owner()).to.equal(owner.address);
  });

  it("should allow EntryPoint to call validateUserOp", async () => {
    // owner 주소를 EntryPoint로 지정했으므로 owner로 호출해야 통과
    const userOp = "0x";
    const userOpHash = ethers.keccak256("0x1234");

    const result = await account.connect(owner).validateUserOp(userOp, userOpHash, 0);
    expect(result).to.equal(0);
  });

  it("should execute a transaction via EntryPoint", async () => {
    // 테스트용으로 other 계정에 1 ETH 보내보기
    const txData = "0x"; // 그냥 이더만 전송
    await owner.sendTransaction({ to: await account.getAddress(), value: ethers.parseEther("1") });

    const beforeBalance = await ethers.provider.getBalance(other.address);

    await account.connect(owner).execute(
      other.address,
      ethers.parseEther("0.5"),
      txData
    );

    const afterBalance = await ethers.provider.getBalance(other.address);
    expect(afterBalance - beforeBalance).to.equal(ethers.parseEther("0.5"));
  });
});
