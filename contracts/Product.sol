// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract ProductRegistry {
    struct Product {
        string id; // UUID cho sản phẩm
        string name; // Tên sản phẩm
        string description; // Mô tả sản phẩm
        uint256 price; // Giá sản phẩm
        uint256 quantity; // Số lượng sản phẩm
        string status; // Trạng thái sản phẩm
        string ipfsUrl; // Đường dẫn IPFS
        address creator; // Địa chỉ ví của người tạo
    }

    mapping(string => Product) private products; // Mapping lưu trữ sản phẩm theo ID

    event ProductAdded(
        string indexed id,
        string name,
        uint256 price,
        bytes32 blockHash
    ); // Sự kiện khi thêm sản phẩm

    event ProductUpdated(string indexed id, string name, uint256 price); // Sự kiện khi cập nhật sản phẩm

    // Thêm sản phẩm mới với ID từ backend
    function addProduct(
        string memory _id,
        string memory _name,
        string memory _description,
        uint256 _price,
        uint256 _quantity,
        string memory _status,
        string memory _ipfsUrl
    ) public {
        require(
            bytes(products[_id].id).length == 0,
            "Product ID already exists"
        ); // Kiểm tra ID đã tồn tại hay chưa

        // Lưu sản phẩm vào mapping
        products[_id] = Product(
            _id,
            _name,
            _description,
            _price,
            _quantity,
            _status,
            _ipfsUrl,
            msg.sender // Lưu địa chỉ ví của người tạo
        );

        // Phát sự kiện khi thêm sản phẩm
        emit ProductAdded(_id, _name, _price, blockhash(block.number));
    }

    // Cập nhật thông tin sản phẩm
    function updateProduct(
        string memory _id, // Sửa đổi kiểu ID thành string
        string memory _name,
        string memory _description,
        uint256 _price,
        uint256 _quantity,
        string memory _status,
        string memory _ipfsUrl
    ) public {
        require(bytes(products[_id].id).length != 0, "Product not found"); // Kiểm tra sản phẩm có tồn tại hay không

        // Cập nhật sản phẩm
        products[_id] = Product(
            _id,
            _name,
            _description,
            _price,
            _quantity,
            _status,
            _ipfsUrl,
            msg.sender // Lưu địa chỉ ví của người tạo
        );

        // Phát sự kiện khi cập nhật sản phẩm
        emit ProductUpdated(_id, _name, _price);
    }

    // Lấy thông tin sản phẩm theo ID
    function getProduct(
        string memory _id // Sửa đổi kiểu ID thành string
    )
        public
        view
        returns (
            string memory name,
            string memory description,
            uint256 price,
            uint256 quantity,
            string memory status,
            string memory ipfsUrl
        )
    {
        require(bytes(products[_id].id).length != 0, "Product not found"); // Kiểm tra sản phẩm có tồn tại

        // Lấy sản phẩm từ mapping
        Product storage p = products[_id];
        return (
            p.name,
            p.description,
            p.price,
            p.quantity,
            p.status,
            p.ipfsUrl
        );
    }
}
