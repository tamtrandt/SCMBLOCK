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
    // Lưu danh sách người sở hữu tokenId
    mapping(uint256 => address[]) private tokenOwners;

    // Kiểm tra xem một địa chỉ đã sở hữu tokenId hay chưa
    mapping(uint256 => mapping(address => bool)) private hasToken;

    // Mảng lưu trữ tất cả các tokenId
    uint256[] private tokenIds;

    // Mapping để kiểm tra xem tokenId đã tồn tại trong mảng chưa
    mapping(uint256 => bool) private tokenIdExists;

    // Sự kiện phát ra mỗi khi trạng thái token thay đổi
    event TokenStateChanged(
        uint256 indexed tokenId,
        string action, // Loại hành động: "MINT", "UPDATE", "BURN", ...
        address indexed creator,
        uint256 timestamp,
        string additionalInfo
    );
    // Mapping lưu trữ các CID của các giao dịch liên quan đến mỗi tokenId
    mapping(uint256 => string[]) public transactionCIDs;

    // Constructor khởi tạo URI chung cho tất cả các token
    constructor() ERC1155("ipfs://{id}.json") Ownable(msg.sender) {}

    // *** Tạo (C): Mint token và lưu metadata CID ***
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

        // Emit sự kiện mint
        emit TokenStateChanged(
            tokenId,
            "MINT",
            msg.sender,
            block.timestamp,
            metadataCID
        );
    }

    // *** Cập nhật (U): Thay đổi số lượng sản phẩm ***
    function updateQuantity(
        uint256 tokenId,
        uint256 newQuantity
    ) external onlyOwner {
        uint256 currentQuantity = productQuantity[tokenId];
        require(newQuantity >= 0, "Quantity must be non-negative");

        // Nếu quantity mới nhỏ hơn quantity cũ, burn bớt token
        if (newQuantity < currentQuantity) {
            uint256 amountToBurn = currentQuantity - newQuantity;
            _burn(msg.sender, tokenId, amountToBurn);
        }
        // Nếu quantity mới lớn hơn quantity cũ, mint thêm token
        else if (newQuantity > currentQuantity) {
            uint256 amountToMint = newQuantity - currentQuantity;
            _mint(msg.sender, tokenId, amountToMint, "");
        }

        // Cập nhật lại thông tin quantity
        productQuantity[tokenId] = newQuantity;

        // Emit sự kiện update quantity
        emit TokenStateChanged(
            tokenId,
            "UPDATE_QUANTITY",
            msg.sender,
            block.timestamp,
            "Quantity updated"
        );
    }

    // *** Cập nhật (U): Thay đổi giá ***
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

    // *** Cập nhật (U): Thay đổi trạng thái ***
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

    // *** Cập nhật (U): Cập nhật metadata ***
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

    // *** Xóa (D): Burn token ***
    function burnProduct(uint256 tokenId, uint256 amount) external {
        require(
            msg.sender == currentOwner[tokenId],
            "Only the current owner can burn this token"
        );

        // Kiểm tra và xóa tokenId khỏi mảng tokenIds nếu số lượng còn lại là 0
        _burn(msg.sender, tokenId, amount);
        productQuantity[tokenId] -= amount;

        // Cập nhật trạng thái nếu cần
        if (productQuantity[tokenId] == 0) {
            productStatus[tokenId] = "not available";

            // Xóa tokenId khỏi mảng tokenIds khi token đã bị burn hết
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

    // Hàm xóa tokenId khỏi mảng tokenIds
    function removeTokenIdFromList(uint256 tokenId) internal {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            if (tokenIds[i] == tokenId) {
                // Di chuyển phần tử cuối cùng của mảng vào vị trí cần xóa
                tokenIds[i] = tokenIds[length - 1];
                tokenIds.pop(); // Giảm độ dài mảng đi 1
                break;
            }
        }
    }

    // Hàm nhận CID từ backend và lưu vào mảng của tokenId
    function storeEventCID(uint256 tokenId, string memory cid) external {
        transactionCIDs[tokenId].push(cid);
    }

    // *** Đọc (R): Lấy thông tin sản phẩm ***
    // Hàm trả về tất cả các CID cho một tokenId
    function getTransactionCIDs(
        uint256 tokenId
    ) external view returns (string[] memory) {
        return transactionCIDs[tokenId];
    }

    //Tra ve Detail TokenId
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

    // Lấy danh sách tất cả tokenId
    struct TokenIdsResponse {
        uint256 count;
        uint256[] product_ids;
    }

    function getAllTokenIds() external view returns (TokenIdsResponse memory) {
        TokenIdsResponse memory response = TokenIdsResponse({
            count: tokenIds.length,
            product_ids: tokenIds
        });
        return response;
    }

    // Lấy tất cả các người sở hữu tokenId
    function getTokenOwners(
        uint256 tokenId
    ) external view returns (address[] memory) {
        return tokenOwners[tokenId];
    }

    // Lấy CID metadata của sản phẩm
    function getMetadataCID(
        uint256 tokenId
    ) external view returns (string memory) {
        return productMetadata[tokenId];
    }

    // Hỗ trợ parse giá
    function parsePrice(string memory price) internal pure returns (uint256) {
        bytes memory b = bytes(price);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] >= 0x30 && b[i] <= 0x39) {
                result = result * 10 + (uint256(uint8(b[i])) - 48);
            }
        }
        return result;
    }
}
