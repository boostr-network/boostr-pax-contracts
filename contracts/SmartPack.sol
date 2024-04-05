// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./SmartCollectible.sol";

interface ISmartPackVault {
    function getTotalStakedTime(uint256 tokenId) external view returns (uint256);
}

contract SmartPack is ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter internal _tokenIds;
  uint256 private seed = 0;

  uint256 public constant COLLECTIBLES_PER_SMART_PACK = 5;
  uint256 public immutable MAX_SUPPLY;
  uint public immutable AMOUNT_CLAIMABLE;
  string public BASE_URL;
  SmartCollectible public immutable smartCollectibleContract;
  address public claimer;
  uint public claimed;
  address public smartPackVaultAddress = address(0);

  mapping(uint256 => uint256) public mintTimestamp;

  event Mint(address sender, uint256 tokenId);
  event ClaimByClaimer(address sender, address receiver, uint256 amount);
  event SmartPackOpen(uint256 tokenId, address sender, uint256[] cards);

  modifier onlyClaimer {
    require(msg.sender == claimer, "Only the claimer address can execute this function.");
    _;
  }

  // creatorAndClaimer: Array of two elements. First element must be the address of collection creator, and the second element must be the address of the claimer
  // amountClaimable: Amount of Smart Packs reserved to be claimed by the claimer address. Must be a number between 0 and maxSupply
  // collectionName: The collection name
  // tokenClasses: Multi-dimensional array of token ids of all the 5 different classes.
  // maxSupply: The maximum supply of Smart Packs of this contract
  // collectionBaseUri: base url for the SmartCollectible contract tokens metadata
  // smartPackBaseUri: base url for the SmartPack tokens metadata
  constructor(address[] memory creatorAndClaimer,
              uint amountClaimable,
              string memory collectionName,
              uint256[][] memory tokenClasses,
              uint maxSupply,
              string memory collectionBaseUri,
              string memory smartPackBaseUri) ERC721 ("SmartPack", "SMARTPACK") {
    require(creatorAndClaimer.length == 2, "Argument creatorAndClaimer length should be 2");
    require(maxSupply >= amountClaimable, "Argument amountClaimable must not be greater than maxSupply");
    require(tokenClasses.length == 5, "Argument tokenClasses: length must be 5");
    require(tokenClasses[0].length > 0, "Argument tokenClasses[0] (token IDs of class Common) should not be empty");
    require(tokenClasses[1].length > 0, "Argument tokenClasses[1] (token IDs of class Uncommon) should not be empty");
    require(tokenClasses[2].length > 0, "Argument tokenClasses[2] (token IDs of class Rare) should not be empty");
    require(tokenClasses[3].length > 0, "Argument tokenClasses[3] (token IDs of class Epic) should not be empty");
    require(tokenClasses[4].length > 0, "Argument tokenClasses[4] (token IDs of class Legendary) should not be empty");
    require(bytes(collectionBaseUri).length > 0, "Argument collectionBaseUri should not be empty");
    require(bytes(smartPackBaseUri).length > 0, "Argument smartPackBaseUri should not be empty");
    BASE_URL = smartPackBaseUri;
    MAX_SUPPLY = maxSupply;
    claimer = creatorAndClaimer[1];
    AMOUNT_CLAIMABLE = amountClaimable;
    smartCollectibleContract = new SmartCollectible(creatorAndClaimer[0], address(this), collectionName, tokenClasses[0], tokenClasses[1], tokenClasses[2], tokenClasses[3], tokenClasses[4], collectionBaseUri);
  }

  function claim(address to, uint256 amount) external onlyClaimer {
    require(claimed + amount <= AMOUNT_CLAIMABLE, "The amount you are trying to claim is not available");
    require(_tokenIds.current() + amount <= MAX_SUPPLY, "Amount exceeds maximum supply");

    for (uint256 i; i < amount; i++){
      uint256 newTokenId = _tokenIds.current();
      string memory finalTokenUri = BASE_URL;
      _safeMint(to, newTokenId);
      _setTokenURI(newTokenId, finalTokenUri);
      _tokenIds.increment();
      mintTimestamp[newTokenId] = block.timestamp;
      emit Mint(to, newTokenId);
    }
    claimed += amount;
    emit ClaimByClaimer(claimer, to, amount);
  }

  function updateClaimer(address _claimer) external onlyOwner {
    require(_claimer != address(0), "Argument _claimer: must ve a valid address");
    claimer = _claimer;
  }

  function totalSupply() external view returns (uint) {
    return _tokenIds.current();
  }

  function maximumSupply() external view returns (uint) {
    return MAX_SUPPLY;
  }

  function amountReservedToClaimer() external view returns (uint) {
    return AMOUNT_CLAIMABLE;
  }

  function generateRandomNumbers() private returns(uint256[] memory){
    uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed)));
    uint256 numbersToGenerate = COLLECTIBLES_PER_SMART_PACK * 2;
    uint256[] memory numbers = new uint256[](numbersToGenerate);
    uint256 maxValue = 10**10;
    seed = randomHash;
    for (uint256 i; i < numbersToGenerate; i++) {
      numbers[i] = randomHash % maxValue;
      randomHash >>= 8;
    }
    return numbers;
  }

  // function currentBoost(uint256 tokenId) public view returns (uint16) {
  //   uint256 totalStakedTime = smartPackVault.totalStakedTime(tokenId) * 4;
  //   uint16 boost = uint16((block.timestamp - mintTimestamp[tokenId]) * 100 / (365 * 2 * 86400));
  //   if (boost > 100) boost = 100;
  //   return boost;
  // }

  function currentBoost(uint256 tokenId) public view returns (uint16) {
    require(_exists(tokenId), "Query for nonexistent token");

    uint256 timeSinceMint = block.timestamp - mintTimestamp[tokenId];
    uint256 boostDuration = 730 days; // Represents 2 years

    uint256 effectiveTimeSinceMint = timeSinceMint;

    if (smartPackVaultAddress != address(0)) {
        ISmartPackVault vault = ISmartPackVault(smartPackVaultAddress);
        uint256 totalStakedTime = vault.getTotalStakedTime(tokenId);
        effectiveTimeSinceMint += totalStakedTime * 3; // Accelerate boost for staked time
    }

    uint16 boost = uint16((effectiveTimeSinceMint * 100) / boostDuration);
    return boost > 100 ? 100 : boost;
  }

  function openSmartPack(uint256 _tokenId) external {
    require(ownerOf(_tokenId) == msg.sender, "Sender address must the owner of the specified Smart Pack ID.");

    uint[] memory cards = new uint[](COLLECTIBLES_PER_SMART_PACK);
    uint[] memory numbers = generateRandomNumbers();
    uint currentCardIndex = 0;

    for (uint256 i = 0; i < COLLECTIBLES_PER_SMART_PACK * 2; i += 2) {
      uint256 card = smartCollectibleContract.mintRandom(msg.sender, currentBoost(_tokenId), numbers[i], numbers[i + 1]);
      cards[currentCardIndex] = card;
      currentCardIndex++;
    }

    _burn(_tokenId);
    emit SmartPackOpen(_tokenId, msg.sender, cards);
  }

  function setSmartPackVaultAddress(address _vaultAddress) external onlyOwner {
    smartPackVaultAddress = _vaultAddress;
  }
}

abstract contract Priceable is Ownable {
  uint256 public CURRENT_PRICE;

  function getPrice() external view returns (uint256) {
    return CURRENT_PRICE;
  }

  function setPrice(uint256 price) external onlyOwner {
    CURRENT_PRICE = price;
  }
}

abstract contract PriceableBundles is Ownable {
  uint256[] public CURRENT_PRICE;

  function getPrice(uint256 bundle) external view returns (uint256) {
    return CURRENT_PRICE[bundle];
  }

  function setPrice(uint256[] memory pricesInWei) external onlyOwner {
    require(pricesInWei.length == 3, "Argument pricesInWei: length must be 3");
    CURRENT_PRICE = pricesInWei;
  }
}

contract BuyableSmartPack is SmartPack, Priceable, PaymentSplitter {
  using Counters for Counters.Counter;

  event IndividualBuy(address sender, address to, uint256 tokenId, uint256 value);
  event BuyAndSend(address sender, address to, uint256 amount, uint256 value);

  // creatorAndClaimer: Array of two elements. First element must be the address of collection creator, and the second element must be the address of the claimer
  // amountClaimable: Amount of Smart Packs reserved to be claimed by the claimer address. Must be a number between 0 and maxSupply
  // collectionName: The collection name
  // tokenClasses: Multi-dimensional array of token ids of all the 5 different classes
  // maxSupply: The maximum supply of Smart Packs of this contract
  // priceInWei: Price for minting a Smart Pack in wei
  // collectionBaseUri: base url for the SmartCollectible contract tokens metadata
  // smartPackBaseUri: base url for the SmartPack tokens metadata
  // royalties: Array of addresses that the contract will split the payments to
  // shares: Array of shares for each address of the royalties array. Both arrays must be the same length
  constructor(address[] memory creatorAndClaimer,
              uint amountClaimable,
              string memory collectionName,
              uint256[][] memory tokenClasses,
              uint maxSupply,
              uint256 priceInWei,
              string memory collectionBaseUri,
              string memory smartPackBaseUri,
              address[] memory royalties,
              uint256[] memory shares) SmartPack(creatorAndClaimer,
                                                        amountClaimable,
                                                        collectionName,
                                                        tokenClasses,
                                                        maxSupply,
                                                        collectionBaseUri,
                                                        smartPackBaseUri)
                                       PaymentSplitter(royalties, shares) {
    CURRENT_PRICE = priceInWei;
  }

  function buyAndSend(address _to, uint256 _amount) external payable {
    require(_amount > 0, "Quantity must be higher than 0");
    require(_amount < 5, "Maximum quantity is 4");
    require(CURRENT_PRICE * _amount == msg.value, "Sent value is not correct");

    uint256 currentTokenId = _tokenIds.current();
    uint256 higherNewTokenId = currentTokenId + _amount - 1;

    require(higherNewTokenId - claimed < MAX_SUPPLY - AMOUNT_CLAIMABLE, "No more available Smart Packs. Please buy in the secondary market");

    for (uint256 i; i < _amount; i++) {
      uint256 newTokenId = _tokenIds.current();
      string memory finalTokenUri = BASE_URL;
      _safeMint(_to, newTokenId);
      _setTokenURI(newTokenId, finalTokenUri);
      _tokenIds.increment();
      mintTimestamp[newTokenId] = block.timestamp;
      emit IndividualBuy(msg.sender, _to, newTokenId, CURRENT_PRICE);
      emit Mint(_to, newTokenId);
    }

    emit BuyAndSend(msg.sender, _to, _amount, msg.value);
  }
}

contract BuyableWithERC20SmartPack is SmartPack, Priceable, PaymentSplitter {
  using Counters for Counters.Counter;

  IERC20 public erc20Token;

  event IndividualBuyWithERC20(address sender, address to, uint256 tokenId, address erc20Token, uint256 value);
  event BuyWithERC20AndSend(address sender, address to, uint256 amount, address erc20Token, uint256 value);

  // creatorAndClaimer: Array of two elements. First element must be the address of collection creator, and the second element must be the address of the claimer
  // amountClaimable: Amount of Smart Packs reserved to be claimed by the claimer address. Must be a number between 0 and maxSupply
  // collectionName: The collection name
  // tokenClasses: Multi-dimensional array of token ids of all the 5 different classes
  // priceInERC20: Price for minting a Smart Pack in amount of ERC20 tokens
  // erc20TokenAddress: Address of the IERC20 compliant token that will be used to pay
  // collectionBaseUri: base url for the SmartCollectible contract tokens metadata
  // smartPackBaseUri: base url for the SmartPack tokens metadata
  // royalties: Array of addresses that the contract will split the payments to
  // shares: Array of shares for each address of the royalties array. Both arrays must be the same length
  constructor(address[] memory creatorAndClaimer,
              uint amountClaimable,
              string memory collectionName,
              uint256[][] memory tokenClasses,
              uint maxSupply,
              uint256 priceInERC20,
              address erc20TokenAddress,
              string memory collectionBaseUri,
              string memory smartPackBaseUri,
              address[] memory royalties,
              uint256[] memory shares) SmartPack(creatorAndClaimer,
                                                        amountClaimable,
                                                        collectionName,
                                                        tokenClasses,
                                                        maxSupply,
                                                        collectionBaseUri,
                                                        smartPackBaseUri)
                                       PaymentSplitter(royalties, shares) {
    erc20Token = IERC20(erc20TokenAddress);
    CURRENT_PRICE = priceInERC20;
  }

  function buyWithERC20AndSend(address _to, uint256 _amount) external {
    require(_amount > 0, "Quantity must be higher than 0");
    require(_amount < 5, "Maximum quantity is 4");

    uint256 currentTokenId = _tokenIds.current();
    uint256 higherNewTokenId = currentTokenId + _amount - 1;

    require(higherNewTokenId - claimed < MAX_SUPPLY - AMOUNT_CLAIMABLE, "No more available Smart Packs. Please buy in the secondary market");

    for (uint256 i; i < _amount; i++) {
      uint256 newTokenId = _tokenIds.current();
      string memory finalTokenUri = BASE_URL;
      _safeMint(_to, newTokenId);
      _setTokenURI(newTokenId, finalTokenUri);
      _tokenIds.increment();
      mintTimestamp[newTokenId] = block.timestamp;
      emit IndividualBuyWithERC20(msg.sender, _to, newTokenId, address(erc20Token), CURRENT_PRICE);
      emit Mint(_to, newTokenId);
    }

    require(erc20Token.transferFrom(msg.sender, address(this), CURRENT_PRICE * _amount), "Error transfering ERC20 tokens");

    emit BuyWithERC20AndSend(msg.sender, _to, _amount, address(erc20Token), CURRENT_PRICE * _amount);
  }
}

contract BuyableSmartPackWithBundles is SmartPack, PriceableBundles, PaymentSplitter {
  using Counters for Counters.Counter;

  uint256[] public AMOUNT_FOR_BUNDLE;

  event IndividualBuy(address sender, uint256 tokenId, uint256 amount);
  event BuyBundle(address sender, address to, uint256 bundle, uint256 value);

  // creatorAndClaimer: Array of two elements. First element must be the address of collection creator, and the second element must be the address of the claimer
  // amountClaimable: Amount of Smart Packs reserved to be claimed by the claimer address. Must be a number between 0 and maxSupply
  // collectionName: The collection name
  // tokenClasses: Multi-dimensional array of token ids of all the 5 different classes
  // maxSupply: The maximum supply of Smart Packs of this contract
  // pricesInWei: Array of three prices for minting each Bundle in wei
  // collectionBaseUri: base url for the SmartCollectible contract tokens metadata
  // smartPackBaseUri: base url for the SmartPack tokens metadata
  // royalties: Array of addresses that the contract will split the payments to
  // shares: Array of shares for each address of the royalties array. Both arrays must be the same length
  constructor(address[] memory creatorAndClaimer,
              uint amountClaimable,
              string memory collectionName,
              uint256[][] memory tokenClasses,
              uint maxSupply,
              uint256[] memory pricesInWei,
              string memory collectionBaseUri,
              string memory smartPackBaseUri,
              address[] memory royalties,
              uint256[] memory shares) SmartPack(creatorAndClaimer,
                                                        amountClaimable,
                                                        collectionName,
                                                        tokenClasses,
                                                        maxSupply,
                                                        collectionBaseUri,
                                                        smartPackBaseUri)
                                        PaymentSplitter(royalties, shares)
  {
    require(pricesInWei.length == 3, "Argument pricesInWei: length must be 3");
    CURRENT_PRICE = pricesInWei;
    AMOUNT_FOR_BUNDLE = [1, 3, 5];
  }

  function buyBundle(address payable _to, uint256 _bundle) external payable {
    require(_bundle < 3, "_bundle must be 0, 1 or 2");
    uint256 amount = AMOUNT_FOR_BUNDLE[_bundle];
    require(CURRENT_PRICE[_bundle] == msg.value, "Sent value is not correct");

    uint256 currentTokenId = _tokenIds.current();
    uint256 higherNewTokenId = currentTokenId + amount - 1;

    require(higherNewTokenId - claimed < MAX_SUPPLY - AMOUNT_CLAIMABLE, "No more available Smart Packs. Please buy in the secondary market");

    for (uint256 i; i < amount; i++) {
      uint256 newTokenId = _tokenIds.current();
      string memory finalTokenUri = BASE_URL;
      _safeMint(_to, newTokenId);
      _setTokenURI(newTokenId, finalTokenUri);
      _tokenIds.increment();
      mintTimestamp[newTokenId] = block.timestamp;
      emit IndividualBuy(_to, newTokenId, CURRENT_PRICE[_bundle] / AMOUNT_FOR_BUNDLE[_bundle]);
      emit Mint(_to, newTokenId);
    }

    emit BuyBundle(msg.sender, _to, _bundle, msg.value);
  }
}
