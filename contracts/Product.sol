// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProductManager is ERC1155, Ownable {
    // Mapping lưu trữ metadata CID cho mỗi tokenId
    mapping(uint256 => string) public productMetadata;

    // Mapping lưu trữ thông tin động về sản phẩm
    mapping(uint256 => string) public productPrice;
    mapping(uint256 => uint256) public productQuantity;
    mapping(uint256 => string) public productStatus;
    mapping(uint256 => address) public currentOwner;

    // Mảng lưu trữ tất cả các tokenId
    uint256[] private tokenIds;

    // Mapping để kiểm tra xem tokenId đã tồn tại trong mảng chưa
    mapping(uint256 => bool) private tokenIdExists;

    // Constructor khởi tạo URI chung cho tất cả các token
    constructor() ERC1155("ipfs://{id}.json") Ownable(msg.sender) {}

    // Mint token và lưu metadata CID
    function mintProduct(
        uint256 tokenId,
        uint256 amount,
        string memory metadataCID,
        string memory price,
        uint256 quantity,
        string memory status
    ) external onlyOwner {
        // Mint token mới
        _mint(msg.sender, tokenId, amount, "");

        // Lưu CID metadata của token
        productMetadata[tokenId] = metadataCID;

        // Lưu thông tin động về giá, số lượng, trạng thái, và chủ sở hữu hiện tại
        productPrice[tokenId] = price;
        productQuantity[tokenId] = quantity;
        productStatus[tokenId] = status;
        currentOwner[tokenId] = msg.sender;

        // Thêm tokenId vào danh sách nếu chưa tồn tại
        if (!tokenIdExists[tokenId]) {
            tokenIds.push(tokenId);
            tokenIdExists[tokenId] = true;
        }
    }

    // Hàm trả về tất cả các tokenId đã được mint
    function getAllTokenIds() external view returns (uint256[] memory) {
        return tokenIds;
    }

    // Các hàm khác không thay đổi
    function updatePrice(
        uint256 tokenId,
        string memory newPrice
    ) external onlyOwner {
        productPrice[tokenId] = newPrice;
    }

    function updateQuantity(
        uint256 tokenId,
        uint256 newQuantity
    ) external onlyOwner {
        productQuantity[tokenId] = newQuantity;
    }

    function updateStatus(
        uint256 tokenId,
        string memory newStatus
    ) external onlyOwner {
        productStatus[tokenId] = newStatus;
    }

    function transferOwnership(uint256 tokenId, address newOwner) external {
        require(
            msg.sender == currentOwner[tokenId],
            "Only current owner can transfer ownership"
        );
        currentOwner[tokenId] = newOwner;
    }

    function updateMetadata(
        uint256 tokenId,
        string memory newMetadataCID
    ) external onlyOwner {
        productMetadata[tokenId] = newMetadataCID;
    }

    function getMetadataCID(
        uint256 tokenId
    ) external view returns (string memory) {
        return productMetadata[tokenId];
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

    function burnProduct(uint256 tokenId, uint256 amount) external {
        require(
            msg.sender == currentOwner[tokenId],
            "Only the current owner can burn this token"
        );

        _burn(msg.sender, tokenId, amount);

        // Cập nhật số lượng sản phẩm
        productQuantity[tokenId] -= amount;

        // Cập nhật trạng thái nếu cần
        if (productQuantity[tokenId] == 0) {
            productStatus[tokenId] = "not available";
        }
    }
}
