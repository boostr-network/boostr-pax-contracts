// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract SmartCollectible is ERC1155, Ownable {
  string public name;
  string public constant symbol = "SMARTCOLLECTIBLE";
  address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
  uint256 public totalSmartCollectibles;
  address public immutable smartPack;
  mapping(Rarity => uint16) public probabilityForRarity;
  mapping(Rarity => int16) public boostForRarity;
  mapping(Rarity => uint256[]) public tokenIdsForRarity;
  mapping(address => bool) public collectionCompleted;
  IERC20 public prizeToken;
  uint256 public prizeAmount;

  enum Rarity {
    Common,
    Uncommon,
    Rare,
    Epic,
    Legendary
  }

  uint16 constant MAX_PROBABILITY = 100;

  event MintSmartCollectible(address sender, uint256 tokenId);
  event CollectionCompleted(address indexed user);

  modifier onlySmartPack {
    require(msg.sender == smartPack, "Only the collection Smart Pack can execute this function.");
    _;
  }

  // creator: address of collection creator
  // smartPackAddress: address of SmartPack contract
  // common: array of token ids of rarity Common
  // uncommon: array of token ids of rarity Uncommon
  // rare: array of token ids of rarity Rare
  // epic: array of token ids of rarity Epic
  // legendary: array of token ids of rarity Legendary
  // baseUrl: base url for the tokens metadata
  constructor(address creator,
              address smartPackAddress,
              string memory collectionName,
              uint256[] memory common,
              uint256[] memory uncommon,
              uint256[] memory rare,
              uint256[] memory epic,
              uint256[] memory legendary,
              string memory baseUri)
              ERC1155 (baseUri) {
    require(common.length > 0, "Argument common should not be empty");
    require(uncommon.length > 0, "Argument uncommon should not be empty");
    require(rare.length > 0, "Argument rare should not be empty");
    require(epic.length > 0, "Argument epic should not be empty");
    require(legendary.length > 0, "Argument legendary should not be empty");
    require(bytes(baseUri).length > 0, "Argument baseUri should not be empty");
    require(smartPackAddress != address(0), "Argument smartPackAddress should not point to zero address");
    require(bytes(collectionName).length > 0, "Argument collectionName should not be empty");

    // Define probabilities for each rarity type. Should sum 100 in total
    probabilityForRarity[Rarity.Common] = 40;
    probabilityForRarity[Rarity.Uncommon] = 25;
    probabilityForRarity[Rarity.Rare] = 15;
    probabilityForRarity[Rarity.Epic] = 10;
    probabilityForRarity[Rarity.Legendary] = 5;

    // Define boost for each rarity type. Should sum 0 in total
    boostForRarity[Rarity.Common] = -32;
    boostForRarity[Rarity.Uncommon] = -13;
    boostForRarity[Rarity.Rare] = 0;
    boostForRarity[Rarity.Epic] = 15;
    boostForRarity[Rarity.Legendary] = 35;

    // Set tokenIds of each rarity
    tokenIdsForRarity[Rarity.Common] = common;
    tokenIdsForRarity[Rarity.Uncommon] = uncommon;
    tokenIdsForRarity[Rarity.Rare] = rare;
    tokenIdsForRarity[Rarity.Epic] = epic;
    tokenIdsForRarity[Rarity.Legendary] = legendary;

    // Minting one of each to the zero address so the tokens actually exist
    for (uint256 i = 0; i < common.length; i++) {
      _mint(BURN_ADDRESS, common[i], 1, "");
    }
    for (uint256 i = 0; i < uncommon.length; i++) {
      _mint(BURN_ADDRESS, uncommon[i], 1, "");
    }
    for (uint256 i = 0; i < rare.length; i++) {
      _mint(BURN_ADDRESS, rare[i], 1, "");
    }
    for (uint256 i = 0; i < epic.length; i++) {
      _mint(BURN_ADDRESS, epic[i], 1, "");
    }
    for (uint256 i = 0; i < legendary.length; i++) {
      _mint(BURN_ADDRESS, legendary[i], 1, "");
    }

    totalSmartCollectibles = common.length + uncommon.length + rare.length + epic.length + legendary.length;
    smartPack = smartPackAddress;
    name = collectionName;

    transferOwnership(creator);
  }

  function _rarityToString(Rarity rarity) internal pure returns (string memory) {
      if (rarity == Rarity.Common) return "Common";
      if (rarity == Rarity.Uncommon) return "Uncommon";
      if (rarity == Rarity.Rare) return "Rare";
      if (rarity == Rarity.Epic) return "Epic";
      if (rarity == Rarity.Legendary) return "Legendary";
      return "Unknown"; // Fallback, should never be reached
  }

  function _getBoostedProbabilityForRarity(Rarity rarity, uint16 currentBoost) internal view returns (uint16) {
    require(currentBoost <= 100, "Boost should be a value between 0-100");

    uint16 defaultProbability = probabilityForRarity[rarity] * 100; // Scale up for precision.
    // Calculate the boost adjustment as a percentage of the default probability, also scaled.
    int16 boostAdjustment = boostForRarity[rarity] * int16(currentBoost);

    // Apply the boost adjustment, ensuring the result is kept in range and scaled.
    int16 adjustedProbability = int16(defaultProbability) + boostAdjustment;

    // Scale back the adjusted probability to ensure it remains within the 0-10000 range after boost application.
    // This adjustment accounts for the original scaling by 100.
    if (adjustedProbability < 0) {
        adjustedProbability = 0;
    } else if (adjustedProbability > 10000) { // 100.00% scaled by 100
        adjustedProbability = 10000;
    }

    return uint16(adjustedProbability);
  }

  function _getRandomTokenIdOfRarity(Rarity rarity, uint256 random) internal view returns (uint256) {
    uint256[] memory tokensAvailableOfRarity = tokenIdsForRarity[rarity];
    uint16 tokenIndex = uint16(random % tokensAvailableOfRarity.length);
    return tokensAvailableOfRarity[tokenIndex];
  }

  function _randomRarity(uint16 currentBoost, uint256 random) internal view returns (Rarity) {
    require(currentBoost < 101, "Boost should be a value between 0-100");

    uint16 value = uint16(random % (MAX_PROBABILITY * 100)); // Scaled for precision

    uint16 accumulatedProbability = 0;

    // Iterate through the rarities incrementally
    for (uint256 i = 0; i <= uint256(Rarity.Legendary); i++) {
      Rarity rarity = Rarity(i);
      uint16 boostedProbability = _getBoostedProbabilityForRarity(rarity, currentBoost);

      // Since we're incrementing, subtract the probability from the total and check if it falls below zero
      accumulatedProbability += boostedProbability;

      if (value < accumulatedProbability) {
        // Log the selected rarity for debugging
        console.log("Selected Rarity:", _rarityToString(rarity));
        return rarity;
      }
    }

    // Log fallback to Common, though logically this point should not be reached
    console.log("Selected Rarity: Common");
    return Rarity.Common;
  }

  function mintRandom(address _toAddress, uint16 boost, uint256 randomForRarity, uint256 randomForTokenId) external onlySmartPack returns (uint256) {
    require(boost < 101, "Boost should be a number between 0 and 100");

    Rarity rarity = _randomRarity(boost, randomForRarity);

    uint256 randomTokenId = _getRandomTokenIdOfRarity(rarity, randomForTokenId);

    _mint(_toAddress, randomTokenId, 1, "0x000");
    totalSmartCollectibles++;

    emit MintSmartCollectible(_toAddress, randomTokenId);

    return randomTokenId;
  }

  /**
  * @dev Complete the collection for the caller if they own at least one of each token.
  * Assumes token IDs are sequential and cover the entire range of tokens required for completion.
  * @notice Callers must own at least one of each token in the sequential range to complete their collection.
  */
  function completeCollection() external {
    //require(msg.sender != owner(), "Owner cannot complete the collection");
    require(!collectionCompleted[msg.sender], "Collection already completed for this address");

    uint256 startId = 0;
    uint256 endId = totalSmartCollectibles; // End ID, based on your total number of collectibles

    // Iterate over the range of token IDs required for a complete collection.
    // This loop assumes that token IDs are sequential.
    for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
      require(balanceOf(msg.sender, tokenId) > 0, "Incomplete collection: missing at least one token.");
    }

    // Mark the collection as completed for the sender and grant the prize.
    collectionCompleted[msg.sender] = true;
    _grantPrize(msg.sender);

    // Emit an event to signal the completion.
    emit CollectionCompleted(msg.sender);
  }

  /**
  * @dev Grants a prize to the specified address.
  * Ensure prize token and amount are set and contract has enough tokens.
  * @param to The recipient of the prize.
  */
  function _grantPrize(address to) private {
    require(address(prizeToken) != address(0), "Prize token has not been set");
    require(prizeAmount > 0, "Prize amount has not been set");
    require(prizeToken.balanceOf(address(this)) >= prizeAmount, "Insufficient prize tokens in the contract");
    bool sent = prizeToken.transfer(to, prizeAmount);
    require(sent, "Failed to send prize");
  }

  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) 
    internal 
    override(ERC1155) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    if (from != address(0)) { // Ignore minting case
        for (uint256 i = 0; i < ids.length; i++) {
            if (collectionCompleted[from]) {
                require(balanceOf(from, ids[i]) > amounts[i], "Cannot transfer the last token of a completed collection");
            }
        }
    }
  }

  function getPrize() public view returns (address, uint256) {
    return (address(prizeToken), prizeAmount);
  }

  function setPrize(address _prizeToken, uint256 _prizeAmount) public onlyOwner {
    require(_prizeToken != address(0), "Prize token address cannot be the zero address");
    prizeToken = IERC20(_prizeToken);
    prizeAmount = _prizeAmount;
  }

  function totalSupply() external view returns (uint) {
    return totalSmartCollectibles;
  }

  function uri(uint256 _id) public view override returns (string memory) {
    return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
  }
}
