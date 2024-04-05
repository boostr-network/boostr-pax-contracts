// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ISmartPack is IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract SmartPackVault is IERC721Receiver, ReentrancyGuard, Ownable {
    ISmartPack public smartPackContract;
    
    // Mapping from token ID to staker's address
    mapping(uint256 => address) public tokenStaker;
    // Mapping from token ID to staking start timestamp
    mapping(uint256 => uint256) public tokenStakedTimestamp;
    // Mapping from token ID to total staked duration
    mapping(uint256 => uint256) public totalStakedTime;

    event Staked(address indexed staker, uint256 tokenId, uint256 timestamp);
    event Unstaked(address indexed staker, uint256 tokenId, uint256 timestamp);

    constructor(address _smartPackAddress) {
        require(_smartPackAddress != address(0), "SmartPack address cannot be zero");
        smartPackContract = ISmartPack(_smartPackAddress);
    }

    function onERC721Received(
        address,
        address /* from */,
        uint256 /* tokenId */,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    function stake(uint256 tokenId) external nonReentrant {
        require(smartPackContract.ownerOf(tokenId) == msg.sender, "Caller is not token owner");
        smartPackContract.safeTransferFrom(msg.sender, address(this), tokenId);

        tokenStaker[tokenId] = msg.sender;
        tokenStakedTimestamp[tokenId] = block.timestamp;

        emit Staked(msg.sender, tokenId, block.timestamp);
    }

    function unstake(uint256 tokenId) external nonReentrant {
        require(tokenStaker[tokenId] == msg.sender, "Caller is not staker");
        require(smartPackContract.ownerOf(tokenId) == address(this), "Token is not staked");

        uint256 stakedDuration = block.timestamp - tokenStakedTimestamp[tokenId];
        totalStakedTime[tokenId] += stakedDuration;

        smartPackContract.safeTransferFrom(address(this), msg.sender, tokenId);
        
        // Reset staking information
        tokenStakedTimestamp[tokenId] = 0;
        tokenStaker[tokenId] = address(0);

        emit Unstaked(msg.sender, tokenId, block.timestamp);
    }

    function getTotalStakedTime(uint256 tokenId) external view returns (uint256) {
        if (smartPackContract.ownerOf(tokenId) == address(this)) {
            uint256 currentStakedDuration = block.timestamp - tokenStakedTimestamp[tokenId];
            return totalStakedTime[tokenId] + currentStakedDuration;
        } else {
            return totalStakedTime[tokenId];
        }
    }
}
