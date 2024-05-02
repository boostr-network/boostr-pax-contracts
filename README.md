# Boostr Pax Contracts

Welcome to the **Boostr Pax Contracts** project! This innovative solution blends the world of non-fungible tokens (NFTs) and collectibles into an exciting, dynamic ecosystem. Our project introduces three main smart contracts: **SmartPack**, **SmartCollectibles** and **SmartPackVault**. Dive into a realm where the thrill of minting, collecting, and the chance to secure rare digital treasures comes to life.

## Smart Packs: Your Gateway to Rarity

Smart Packs are the cornerstone of our ecosystem, functioning as ERC-721 contracts. They offer you a unique and interactive way to acquire and engage with digital collectibles. Here's what makes them special:

- **Minting Flexibility:** Secure your Smart Pack through direct purchase using the native currency or a specified ERC-20 token. Alternatively, they can be pre-minted by the contract owner and later opened to reveal the treasures within.
- **Discover the Unseen:** Upon opening, a Smart Pack reveals 5 random ERC-1155 tokens from its linked Collectibles contract, curated at the time of deployment.
- **A Burn with Purpose:** Open your Smart Pack to not only discover your collectibles but also send the pack itself to the burn address, ensuring a cycle of renewal and rarity.
- **Patience Pays Off:** Hold onto your Smart Pack for up to 2 years to enhance your chances of uncovering more rare collectibles from the linked collection, or stake your SmartPack to reduce the time of reaching maximum boost for up to 6 months.

## Smart Collectibles: A Spectrum of Rarity

As the offspring of Smart Packs, Smart Collectibles are structured as ERC-1155 contracts, embodying versatility and efficiency. They serve as the repository of digital treasures that Smart Packs unlock. Their distinct features include:

- **Pre-defined Rarity Classes:** Every token ID within a collection is assigned a rarity class, dictating the probability of its acquisition upon opening a Smart Pack.
- **Exclusive Minting Rights:** Primarily, only a Smart Pack contract can mint tokens from its associated Collectibles contract, maintaining exclusivity and rarity. However, Collectibles contracts retain the flexibility to be deployed and utilized independently if desired.
- **Tailored Probabilities:** The architecture allows for the customization of rarity probabilities, ensuring a balanced and exciting distribution of collectibles.
- **Reward Capabilities:** Smart Collectibles contracts can implement reward mechanisms, allowing collectors to earn additional benefits or incentives based on their interactions with the ecosystem. This could include rewards for completing collections, participating in staking activities, or achieving specific milestones.

## SmartPackVault: Secure Storage for Digital Assets and Staking

The SmartPackVault contract serves as a secure vault for storing digital assets within the Boostr Network ecosystem. It facilitates staking and unstaking of Smart Packs while maintaining a record of staking durations and providing event emission for monitoring activities.

- **Reduce Time To Reach Maximum Boost:** Stake Smart Pack for up to reduce the time of reaching maximum boost for up to 6 months.
- **Earn ERC20 tokens:** Stake Smart Pack to earn ERC20 tokens and feed the prize pool for collectors.

## Ensuring Unpredictability

We employ a pseudo-random approach to determine the collectibles you receive from a Smart Pack. This method is designed to be sufficiently unpredictable for our use case, adding an element of surprise and excitement to each opening.

## Developer-Friendly Ecosystem

Our contracts are built with developers in mind:

- **Open-Source and Accessible:** Jumpstart your project or integrate with our ecosystem seamlessly. Our codebase is designed for clarity and ease of use.
- **Comprehensive Documentation:** Get up and running quickly with detailed guides and examples.
- **Community Support:** Join our developer community for discussions, support, and collaboration.

### Get Started

Embark on your journey into the world of Smart Pack NFT Contracts. Whether you're a collector, a developer looking to build on top of our infrastructure, or someone curious about the possibilities of NFTs and digital collectibles, our platform is designed to provide an engaging and rewarding experience.

Let's unlock the world of digital rarity together. Happy collecting!

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```
