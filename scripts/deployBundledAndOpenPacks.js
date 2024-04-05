const { ethers, waffle } = require("hardhat");

const main = async () => {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  console.log("");

  const smartPackContractFactory = await ethers.getContractFactory('BuyableSmartPackWithBundles');
  const smartPackContract = await smartPackContractFactory.deploy(
    [deployer.address, deployer.address],
    100,
    "Taraxa Sticker Album",
    [
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      [11, 12, 13, 14, 15],
      [16, 17, 18, 19],
      [20, 21, 22],
      [23, 24, 25]
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

  const smartCollectibleContractFactory = await ethers.getContractFactory('SmartCollectible');
  const smartCollectibleContract = await smartCollectibleContractFactory.attach(smartCollectibleContractAddress);

  let txn
  for (let i = 0; i < 1; i++) {
    txn = await smartPackContract.buyBundle(deployer.address, 0, {value: ethers.utils.parseEther("0.001")})
    await txn.wait()
    console.log("Bought pack", i)

    const provider = waffle.provider;
    const balanceInWei = await provider.getBalance(deployer.address);
    console.log("balance", balanceInWei.toString());
  }
  console.log("Bought 10 packs")

  txn = await smartPackContract.buyBundle(deployer.address, 1, {value: ethers.utils.parseEther("0.0025")})
  await txn.wait()
  console.log("Bought 1 bundle of 3 packs")

  all2 = await smartPackContract.totalSupply()
  console.log("total packs:", all2.toNumber())

  for (let i = 0; i < 4; i++) {
    txn = await smartPackContract.buyBundle(deployer.address, 2, {value: ethers.utils.parseEther("0.004")})
    await txn.wait()
    console.log("Bought 1 bundle of 5 packs", i + 13)
  }
  console.log("Bought 20 packs");

  txn = await smartPackContract.claim(deployer.address, 5)
  console.log("claimed 5 packs")

  txn = await smartPackContract.claim(deployer.address, 4)
  console.log("claimed 4 packs")

  txn = await smartPackContract.claim(deployer.address, 1)
  console.log("claimed 1 pack")

  all2 = await smartPackContract.totalSupply()
  console.log("total packs:", all2.toNumber())

  // should be 34


  // txn = await smartPackContract.buyBundle(deployer.address, 1, 0, {value: ethers.utils.parseEther("0.001")})
  // txn = await smartPackContract.buyBundle(deployer.address, 1, 1, {value: ethers.utils.parseEther("0.003")})

  for (let i = 0; i < all2.toNumber(); i++) {
    console.log("Opening Smart Pack", await smartPackContract.tokenURI(i));
    txn = await smartPackContract.openSmartPack(i)
    await txn.wait()
  }

  let balance
  for (let i = 0; i < 26; i++) {
    balance = await smartCollectibleContract.balanceOf(deployer.address, i)
    console.log("balance", balance.toNumber())
  }

  let all = await smartCollectibleContract.totalSupply()
  console.log("Total Smart Collectibles:", all.toNumber())

  console.log("Total Smart Packs:", all2.toNumber())
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
