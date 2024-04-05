const { ethers } = require("hardhat");

const main = async () => {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  console.log("");

  const smartPackContractFactory = await ethers.getContractFactory('BuyableSmartPackWithBundles');
  const smartPackContract = await smartPackContractFactory.deploy(
    ["0x229E6f826DCdf76321723905EBA1A9f8331D5532", "0x229E6f826DCdf76321723905EBA1A9f8331D5532"],
    100,
    "Taraxa Sticker Album",
    [
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      [11, 12, 13, 14, 15],
      [16, 17, 18, 19, 20],
      [21, 22, 23],
      [24]
    ],
    10000,
    [ethers.utils.parseEther("0.001").toString(), ethers.utils.parseEther("0.0025").toString(), ethers.utils.parseEther("0.004").toString()],
    "ipfs://smartcollectiblesemetadata/",
    "ipfs://smartpackmetadata",
    [deployer.address],
    [100]
  );

  await smartPackContract.deployed();
  console.log("BuyableSmartPackWithBundles contract deployed to:", smartPackContract.address);

  const smartCollectibleContractAddress = await smartPackContract.smartCollectibleContract();
  console.log("SmartCollectible contract deployed to:", smartCollectibleContractAddress);
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();
