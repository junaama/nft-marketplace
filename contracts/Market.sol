// contracts/Market.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
// utility to protect from multiple requests
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    // Number of items sold
    // We need to know the length of the arrays because SOL doesn't have dynamic arrays
    Counters.Counter private _itemsSold;

    // Owner of the contract - Determine the owner of the contract so we can know who the commission goes to
    address payable owner;
    // 18 decimals, technically a matic
    // 0.025 MATIC = 2 cents
    uint256 listingPrice = 0.025 ether;
    
    // The owner of this contract is the person deploying it
    constructor() {
        owner = payable(msg.sender);
    }

    // For each individual market item
    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    // Keep up with all items that were created
    // Item Id returns MarketItem
    mapping(uint256 => MarketItem) private idToMarketItem;

    // A way to listen to events from client
    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    /** Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /** Places an item for sale on the marketplace */

    // Parameters: Contract address for NFT, tokenID from contract, price for that token
    // nonReentrant modifier: Prevent reentry attack
    function createMarketItem (address nftContract, uint256 tokenId, uint256 price) public payable nonReentrant {
        // Can't list for free
        require(price > 0, "Price must be at least 1 wei");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        // Id for marketplace item that is currently for sale
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        // Creation of market item
        // Seller = msg.sender
        // Owner = empty address because nobody currently owns it
        // False: Not sold yet
        idToMarketItem[itemId] = MarketItem(itemId,nftContract,tokenId,payable(msg.sender),payable(address(0)),price,false);

        // Transfer ownership of NFT to contract => Contract will take ownership to transfer to the next person

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        // TODO: Create methods for cancelling transfers
        
        // Emit event with values previously set
        emit MarketItemCreated(itemId,nftContract,tokenId,msg.sender,address(0),price,false);
    }

    /** Creates the sale of a marketplace item */
    /** Transfers ownership of the item, as well as funds between parties */

    function createMarketSale(address nftContract,uint256 itemId) public payable nonReentrant {
        // Reference to price/tokenID by using MarketItem mapping
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;

        require(msg.value == price, "Please submit the asking price to order to complete order");

        // Transfer value of transaction to seller
        idToMarketItem[itemId].seller.transfer(msg.value);

        // Transfer ownership of token to msg.sender
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        // Local value of owner to msg.sender
        idToMarketItem[itemId].owner = payable(msg.sender);
        // Set boolean of sold to true
        idToMarketItem[itemId].sold = true;
        // Increment to keep track of total items sold
        _itemsSold.increment();

        // Pay owner of contract
        payable(owner).transfer(listingPrice);
    }

     /* Returns all unsold market items */
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        // Total number of items currently created
        uint itemCount = _itemIds.current();
        // Subtract itemCount and itemsSold
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        // Local value for incrementing a number for number of items created
        uint currentIndex = 0;

        // If item has an empty address then it has not been sold then we increment currentIndex
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);

        // Loop over number of items created
        // Access owner value in idToMarketItem mapping and check address
        for (uint i = 0; i < itemCount; i++) {
        if (idToMarketItem[i + 1].owner == address(0)) {
            uint currentId =  i + 1;
            MarketItem storage currentItem = idToMarketItem[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1;
        }
        }
        return items;
    }

    /* Returns only items that a user has purchased */
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
            itemCount += 1;
        }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].owner == msg.sender) {
            uint currentId =  i + 1;
            MarketItem storage currentItem = idToMarketItem[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1;
        }
        }
        return items;
    }

    /* Returns only items a user has created */
    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].seller == msg.sender) {
            itemCount += 1;
        }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].seller == msg.sender) {
            uint currentId = i + 1;
            MarketItem storage currentItem = idToMarketItem[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1;
        }
        }
        return items;
    }

}