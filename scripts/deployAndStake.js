const { ethers } = require("hardhat");

const main = async () => {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  console.log("");

  const smartPackContractFactory = await ethers.getContractFactory('BuyableSmartPack');
  const smartPackContract = await smartPackContractFactory.deploy(
    [deployer.address, deployer.address],
    1,
    "Taraxa Sticker Album",
    [
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      [11, 12, 13, 14, 15],
      [16, 17, 18, 19, 20],
      [21, 22, 23],
      [24]
    ],
    10,
    ethers.utils.parseEther('0.0001'),
    "ipfs://smartcollectiblesemetadata/",
    "ipfs://smartpackmetadata",
    [deployer.address],
    [100]
  );
  await smartPackContract.deployed();
  console.log("SmartPack contract deployed to:", smartPackContract.address);

  const smartCollectibleContractAddress = await smartPackContract.smartCollectibleContract();
  console.log("SmartCollectible contract deployed to:", smartCollectibleContractAddress);

  const smartPackVaultContractAddress = await smartPackContract.smartPackVaultContract();
  const smartPackVaultContractFactory = await ethers.getContractFactory('SmartPackVault');
  const smartPackVaultContract = await smartPackVaultContractFactory.attach(smartPackVaultContractAddress);
  console.log("SmartPackVault contract deployed to:", smartPackVaultContractAddress);

  console.log("")
  console.log("Claiming Smart Pack...")
  txn = await smartPackContract.claim(deployer.address, 1);
  await txn.wait();
  console.log("Claimed 1 Smart Pack and sent to address ", deployer.address);

  console.log("")
  let ownerOfTokenId0 = await smartPackContract.ownerOf(0);
  console.log("Current owner of Smart Pack #0:", ownerOfTokenId0.toString());

  console.log("")
  console.log("Approving Smart Pack #0 for staking...")
  // Approve the SmartPackVault contract to transfer the SmartPack on behalf of the owner
  txn = await smartPackContract.approve(smartPackVaultContract.address, 0);
  await txn.wait();
  console.log("Approved Smart Pack Vault to stake Smart Pack #0");

  console.log("")
  console.log("Staking Smart Pack #0...");
  // Now stake the SmartPack
  txn = await smartPackVaultContract.stake(0, { from: deployer.address });
  await txn.wait();
  console.log("Staked Smart Pack #0");

  console.log("")
  ownerOfTokenId0 = await smartPackContract.ownerOf(0);
  console.log("Current owner of Smart Pack #0:", ownerOfTokenId0.toString());

  console.log("")
  console.log("Unstaking Smart Pack #0...");
  // Now stake the SmartPack
  txn = await smartPackVaultContract.unstake(0, { from: deployer.address });
  await txn.wait();
  console.log("Unstaked Smart Pack #0");

  console.log("")
  ownerOfTokenId0 = await smartPackContract.ownerOf(0);
  console.log("Current owner of Smart Pack #0:", ownerOfTokenId0.toString());
};

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
