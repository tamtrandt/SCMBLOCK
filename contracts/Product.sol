// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ProductManager is ERC1155, Ownable {
    using Address for address payable;

    // Mappings for product metadata and dynamic attributes
    mapping(uint256 => string) public productMetadata;
    mapping(uint256 => string) public productPrice;
    mapping(uint256 => uint256) public productQuantity;
    mapping(uint256 => string) public productStatus;
    mapping(uint256 => address) public currentOwner;

    // Token ownership tracking
    mapping(uint256 => address[]) private tokenOwners;
    mapping(uint256 => mapping(address => bool)) private hasToken;

    // Track all token IDs and existence
    uint256[] private tokenIds;
    mapping(uint256 => bool) private tokenIdExists;

    struct TokenIdsResponse {
        uint256 count;
        uint256[] product_ids;
    }

    // Events for token state changes
    event TokenStateChanged(
        uint256 indexed tokenId,
        string action,
        address indexed creator,
        uint256 timestamp,
        string additionalInfo
    );

    // Transaction CID mapping
    mapping(uint256 => string[]) public transactionCIDs;

    constructor() ERC1155("ipfs://{id}.json") Ownable(msg.sender) {}

    function mintProduct(
        uint256 tokenId,
        uint256 amount,
        string memory metadataCID,
        string memory price,
        uint256 quantity,
        string memory status
    ) external onlyOwner {
        _mint(msg.sender, tokenId, amount, "");
        productMetadata[tokenId] = metadataCID;
        productPrice[tokenId] = price;
        productQuantity[tokenId] = quantity;
        productStatus[tokenId] = status;
        currentOwner[tokenId] = msg.sender;

        if (!tokenIdExists[tokenId]) {
            tokenIds.push(tokenId);
            tokenIdExists[tokenId] = true;
        }
        tokenOwners[tokenId].push(msg.sender);

        emit TokenStateChanged(
            tokenId,
            "MINT",
            msg.sender,
            block.timestamp,
            metadataCID
        );
    }

    function updatePrice(
        uint256 tokenId,
        string memory newPrice
    ) external onlyOwner {
        productPrice[tokenId] = newPrice;
        emit TokenStateChanged(
            tokenId,
            "UPDATE_PRICE",
            msg.sender,
            block.timestamp,
            newPrice
        );
    }

    function updateQuantity(
        uint256 tokenId,
        uint256 newQuantity
    ) external onlyOwner {
        uint256 currentQuantity = productQuantity[tokenId];
        require(newQuantity >= 0, "Quantity must be non-negative");

        if (newQuantity < currentQuantity) {
            _burn(msg.sender, tokenId, currentQuantity - newQuantity);
        } else if (newQuantity > currentQuantity) {
            _mint(msg.sender, tokenId, newQuantity - currentQuantity, "");
        }

        productQuantity[tokenId] = newQuantity;

        emit TokenStateChanged(
            tokenId,
            "UPDATE_QUANTITY",
            msg.sender,
            block.timestamp,
            "Quantity updated"
        );
    }

    function updateStatus(
        uint256 tokenId,
        string memory newStatus
    ) external onlyOwner {
        productStatus[tokenId] = newStatus;
        emit TokenStateChanged(
            tokenId,
            "UPDATE_STATUS",
            msg.sender,
            block.timestamp,
            newStatus
        );
    }

    function updateMetadata(
        uint256 tokenId,
        string memory newMetadataCID
    ) external onlyOwner {
        productMetadata[tokenId] = newMetadataCID;
        emit TokenStateChanged(
            tokenId,
            "UPDATE_METADATA",
            msg.sender,
            block.timestamp,
            newMetadataCID
        );
    }

    function buyTokens(
        uint256[] memory tokenIdsToBuy,
        uint256[] memory amountsToBuy,
        uint256 totalPrice
    ) external payable {
        require(
            tokenIdsToBuy.length == amountsToBuy.length,
            "Mismatched inputs"
        );
        require(msg.value == totalPrice, "Incorrect ETH amount");

        address seller = currentOwner[tokenIdsToBuy[0]];
        payable(seller).sendValue(totalPrice);

        for (uint256 i = 0; i < tokenIdsToBuy.length; i++) {
            uint256 tokenId = tokenIdsToBuy[i];
            uint256 amount = amountsToBuy[i];

            require(
                productQuantity[tokenId] >= amount,
                "Insufficient token quantity"
            );
            productQuantity[tokenId] -= amount;
            _safeTransferFrom(seller, msg.sender, tokenId, amount, "");

            for (uint256 j = 0; j < amount; j++) {
                tokenOwners[tokenId].push(msg.sender);
            }
        }

        emit TokenStateChanged(
            tokenIdsToBuy[0],
            "SALE",
            msg.sender,
            block.timestamp,
            "Tokens sold"
        );
    }

    function burnProduct(uint256 tokenId, uint256 amount) external {
        require(
            msg.sender == currentOwner[tokenId],
            "Only the current owner can burn this token"
        );
        _burn(msg.sender, tokenId, amount);
        productQuantity[tokenId] -= amount;

        if (productQuantity[tokenId] == 0) {
            productStatus[tokenId] = "not available";
            removeTokenIdFromList(tokenId);
        }

        emit TokenStateChanged(
            tokenId,
            "BURN",
            msg.sender,
            block.timestamp,
            "Token burned"
        );
    }

    function removeTokenIdFromList(uint256 tokenId) internal {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            if (tokenIds[i] == tokenId) {
                tokenIds[i] = tokenIds[length - 1];
                tokenIds.pop();
                break;
            }
        }
    }

    function storeEventCID(uint256 tokenId, string memory cid) external {
        transactionCIDs[tokenId].push(cid);
    }

    function getTransactionCIDs(
        uint256 tokenId
    ) external view returns (string[] memory) {
        return transactionCIDs[tokenId];
    }

    function getProductInfo(
        uint256 tokenId
    )
        external
        view
        returns (string memory, string memory, uint256, string memory, address)
    {
        return (
            productMetadata[tokenId],
            productPrice[tokenId],
            productQuantity[tokenId],
            productStatus[tokenId],
            currentOwner[tokenId]
        );
    }

    function getAllTokenIds() external view returns (TokenIdsResponse memory) {
        return
            TokenIdsResponse({count: tokenIds.length, product_ids: tokenIds});
    }

    function getTokenOwners(
        uint256 tokenId
    ) external view returns (address[] memory) {
        return tokenOwners[tokenId];
    }

    function getMetadataCID(
        uint256 tokenId
    ) external view returns (string memory) {
        return productMetadata[tokenId];
    }
}
