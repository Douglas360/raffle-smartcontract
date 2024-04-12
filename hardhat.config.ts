import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/eW-tnP4AAByG93fex0dqqcE2i2u008GP",
      accounts: [
        "62c98fabbb5a864c06a4a2f8e58e8ff38c9b2bee3695644a87c0f1d35c86f7a8",
      ],
    },
    mumbai: {
      url: "https://public.stackup.sh/api/v1/node/polygon-mumbai",
      accounts: [
        "62c98fabbb5a864c06a4a2f8e58e8ff38c9b2bee3695644a87c0f1d35c86f7a8",
      ],
    },
  },
};

export default config;
