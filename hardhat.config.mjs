import "@nomicfoundation/hardhat-toolbox";

export default {
  solidity: "0.8.20",
  networks: {
    hardhat: {}, // 로컬 네트워크
    localhost: {
      url: "http://127.0.0.1:8545"
    }
    // 필요하면 sepolia, goerli 같은 테스트넷 추가 가능
    // sepolia: {
    //   url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
    //   accounts: [process.env.PRIVATE_KEY]
    // }
  }
};
