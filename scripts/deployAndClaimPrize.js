const { ethers } = require("hardhat");

const main = async () => {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", ethers.utils.formatEther(await deployer.getBalance()), "ETH");
  console.log("");

  // Deploy ERC20 Token for Prize
  const SmartToken = await ethers.getContractFactory("SmartToken");
  const prizeToken = await SmartToken.deploy("Axarat Token", "AXARAT", ethers.utils.parseEther("1000000000"));
  await prizeToken.deployed();
  console.log("Axarat Token deployed to:", prizeToken.address);

  // Deploy BuyableSmartPack, which in turn deploys SmartCollectible
  const BuyableSmartPack = await ethers.getContractFactory("BuyableSmartPack");
  const buyableSmartPack = await BuyableSmartPack.deploy(
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
  await buyableSmartPack.deployed();
  console.log("BuyableSmartPack deployed to:", buyableSmartPack.address);

  // Retrieve the deployed SmartCollectible contract address
  const smartCollectibleAddress = await buyableSmartPack.smartCollectibleContract(); // Ensure you have such a getter method
  console.log("SmartCollectible contract deployed to:", smartCollectibleAddress);

  // Interact with SmartCollectible Contract
  const SmartCollectible = await ethers.getContractFactory("SmartCollectible");
  const smartCollectible = SmartCollectible.attach(smartCollectibleAddress);

  // Set Prize for the SmartCollectible contract (assuming setPrize function exists)
  const setPrizeTx = await smartCollectible.setPrize(prizeToken.address, ethers.utils.parseEther("1000000"));
  await setPrizeTx.wait();
  console.log("Prize set to 1000000 AXARAT tokens for SmartCollectible");

  // Ensure the SmartCollectible contract has enough ERC20 tokens to distribute as prizes
  const transferTx = await prizeToken.transfer(smartCollectible.address, ethers.utils.parseEther("100000000"));
  await transferTx.wait();
  console.log("Transferred 100000000 AXARAT tokens to SmartCollectible contract for prizes");

  // Example action: Claim a collectible or complete a collection
  // This step is highly dependent on your SmartCollectible contract's API
  console.log("Attempting to claim or complete collection...");

  // The specific function to call for completing the collection might vary
  // Assuming a function that allows claiming or marking the collection as complete
  const claimTx = await smartCollectible.completeCollection(); // Adjust according to your contract's function
  await claimTx.wait();
  console.log("Collection completed or claimed");

  // Check ERC20 Balance for the caller
  const balance = await prizeToken.balanceOf(deployer.address);
  console.log("Deployer's SmartToken balance:", ethers.utils.formatEther(balance), "AXARAT");

  console.log("Attempting to transfer token ID 4 to recipient...");
  const recipientAddress = "0xac197d27E9d29f1cD234b896a77145E45BBfe7bc";
  const transferCollectibleTx = await smartCollectible.safeTransferFrom(deployer.address, recipientAddress, 4, 1, "0x00");
  await transferCollectibleTx.wait();
  console.log(`Transferred token ID 4 from deployer to recipient (${recipientAddress}).`);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
