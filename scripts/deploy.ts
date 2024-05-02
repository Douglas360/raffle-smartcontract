import hre from "hardhat";

async function main() {
  const contractFactory = await hre.ethers.getContractFactory(
    "RaffleV2ChainLink"
  );
  const contract = await contractFactory.deploy();
  console.log("Contract deployed to address:", contract.target);
  /*let tx;

  tx = await contract.criarRifa(
    "Rifa 2",
    "https://black-tropical-parakeet-136.mypinata.cloud/ipfs/QmeuUiE6HYWkFAiDTVWpY2UHjvok6XB3SmuAEYod4rwVCY",
    2000000000000000000n, // 2 ETH em wei Valor do premio
    100000000000000000n, // 0.1 ETH em wei Valor do ticket
    10 // 10 tickets
  );
  await tx.wait();

  console.log("Rifa criada com sucesso!" + tx.hash);

  tx = await contract.comprarBilhete(1, 9, { value: 9000000000000000000n });
  //send value 0.1 ETH
  await tx.wait();

  console.log("Bilhete comprado com sucesso!" + tx.hash);*/
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
