import hre from "hardhat";

async function main() {
  const contractFactory = await hre.ethers.getContractFactory("Rifa");
  const contract = await contractFactory.deploy();
  console.log("Contract deployed to address:", contract.target);
}

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};
runMain();
