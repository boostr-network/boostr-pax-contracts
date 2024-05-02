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

  const smartCollectibleContractFactory = await ethers.getContractFactory('SmartCollectible');
  const smartCollectibleContract = await smartCollectibleContractFactory.attach(smartCollectibleContractAddress);
  
  console.log("")
  let txn = await smartPackContract.claim(deployer.address, 1);
  await txn.wait();

  console.log("Claimed 1 Smart Pack and sent to address ", deployer.address);
  console.log("")
  console.log("Minting 1 Smart Pack...");

  txn = await smartPackContract.buyAndSend(deployer.address, 1, { value: ethers.utils.parseEther("0.0001") })
  await txn.wait()
  
  console.log("Minted Smart Pack #1")
  console.log("")
  console.log("Minting 4 Smart Packs...")

  txn = await smartPackContract.buyAndSend(deployer.address, 4, { value: ethers.utils.parseEther("0.0004") })
  await txn.wait()

  console.log("Minted Smart Packs #2, #3, #4 and #5")
  console.log("")
  console.log("Opening Smart Pack #0...")

  smartPackContract.on("SmartPackOpen", (tokenId, sender, smartCollectibles) => {
    console.log("Smart Collectibles obtained: ", smartCollectibles.map(sc => sc.toString()));
  })

  const gasLimit = 1200000;

  txn = await smartPackContract.openSmartPack(0, { gasLimit })
  await txn.wait()

  console.log("Wow. You got impressive NFTs, what a lucky guy!")
  console.log("")
  console.log("Opening Smart Pack #1...")

  txn = await smartPackContract.openSmartPack(1, { gasLimit })
  await txn.wait()
  
  console.log("Wow. You got impressive NFTs, what a lucky guy!")
  console.log("")
  console.log("Opening Smart Pack #2...")

  txn = await smartPackContract.openSmartPack(2, { gasLimit })
  await txn.wait()
  
  console.log("Wow. You got impressive NFTs, what a lucky guy!")
  console.log("")
  console.log("Opening Smart Pack #3...")

  txn = await smartPackContract.openSmartPack(3, { gasLimit })
  await txn.wait()
  
  console.log("Wow. You got impressive NFTs, what a lucky guy!")
  console.log("")
  console.log("Opening Smart Pack #4...")

  txn = await smartPackContract.openSmartPack(4, { gasLimit })
  await txn.wait()
  
  console.log("Wow. You got impressive NFTs, what a lucky guy!")
  console.log("")
  console.log("Opening Smart Pack #5...")

  txn = await smartPackContract.openSmartPack(5, { gasLimit })
  await txn.wait()
  
  console.log("Wow. You got impressive NFTs, what a lucky guy!")
  console.log("")

  const releasable = await smartPackContract.functions['releasable(address)'](deployer.address);
  console.log(`Releasable wei for ${deployer.address}: ${releasable.toString()}`);

  txn = await smartPackContract.functions['release(address)'](deployer.address);
  await txn.wait();

  console.log("")
  console.log(`Withdrew ${releasable} wei for ${deployer.address}`);
  console.log("")

  for (let i = 0; i <= 24; i++) {
    const balance = await smartCollectibleContract.balanceOf(deployer.address, i);
    console.log(`Balance of Smart Collectible #${i} for ${deployer.address}: ${balance.toString()}`);
  }

  console.log("")

  let smartPackPrice = await smartPackContract.getPrice();
  console.log("Current Smart Pack price:", smartPackPrice.toString());
  console.log("")

  let totalSmartCollectibles = await smartCollectibleContract.totalSupply();
  console.log("Total Smart Collectibles:", totalSmartCollectibles.toString());
  console.log("")

  let totalSmartPacks = await smartPackContract.totalSupply();
  console.log("Total Smart Packs:", totalSmartPacks.toString());

  let smartPackContractOwner = await smartPackContract.owner();
  console.log("Smart Pack contract owner:", smartPackContractOwner.toString());
  let smartCollectibleContractOwner = await smartCollectibleContract.owner();
  console.log("Smart Collectible contract owner:", smartCollectibleContractOwner.toString());
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
