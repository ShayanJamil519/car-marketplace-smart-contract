const { ethers } = require("hardhat");

async function main() {
  // Setup accounts & variables
  const [deployer] = await ethers.getSigners();

  // Deploy contract
  const CarMarketplace = await ethers.getContractFactory("CarMarketplace");
  const carMarketplace = await CarMarketplace.deploy();
  await carMarketplace.deployed();

  console.log(
    `Deployed CarMarketplace Contract at: ${carMarketplace.address}\n`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
