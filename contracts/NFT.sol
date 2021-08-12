// contracts/NFT.sol
//SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.3;
// Utility to increment integers
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    // Token ids which will increment for each new token
    Counters.Counter private _tokenIds;
    // Address of marketplace for NFT to interact with
    
    address contractAddress;
    // Setting contract address
    // Deploying the market, then the contract
    constructor(address marketplaceAddress) ERC721("NFT Marketplace", "METT"){
        contractAddress = marketplaceAddress;
    }
    // For minting new tokens
    // Only need tokenURI because we have metadata available
    function createToken(string memory tokenURI) public returns (uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        // Gives the marketplace the approval to transact this token between users
        setApprovalForAll(contractAddress, true);
        // We return the token so we can get the data for the client
        return newItemId;
    }
}