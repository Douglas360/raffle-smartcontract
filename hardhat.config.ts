import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import path from "path";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  /*paths: {
    artifacts: path.join("C:", "Projetos", "rifachain", "src", "abis"),
  },*/
  networks: {
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/eW-tnP4AAByG93fex0dqqcE2i2u008GP",
      accounts: [
        "12213c72584923c5155b476016968256edce5c8a04c2c789d5400a347e30df64",
      ],
    },
    amoy: {
      url: "https://rpc-amoy.polygon.technology",
      accounts: [
        "62c98fabbb5a864c06a4a2f8e58e8ff38c9b2bee3695644a87c0f1d35c86f7a8",
      ],
    },
    avalanche: {
      url: "https://avalanche-fuji.blockpi.network/v1/rpc/public",
      accounts: [
        "62c98fabbb5a864c06a4a2f8e58e8ff38c9b2bee3695644a87c0f1d35c86f7a8",
      ],
    },
    localhost: {
      url: "http://127.0.0.1:8545/",
      accounts: [
        "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
      ],
    },
  },
};

export default config;
