// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract ProductRegistry {
    struct Product {
        string id; // UUID cho sản phẩm
        string name; // Tên sản phẩm
        string description; // Mô tả sản phẩm
        string price; // Giá sản phẩm (đã chuyển từ uint256 sang string)
        uint256 quantity; // Số lượng sản phẩm
        string brand; // Thương hiệu sản phẩm
        string category; // Danh mục sản phẩm
        string size; // Kích thước sản phẩm
        string status; // Trạng thái sản phẩm
        string store;
        string[] cids; // Đường dẫn IPFS
        address creator; // Địa chỉ ví của người tạo
    }

    mapping(string => Product) private products; // Mapping lưu trữ sản phẩm theo ID
    string[] private productIds; // Mảng lưu trữ ID của tất cả các sản phẩm

    event ProductAdded(
        string indexed id,
        string name,
        string price,
        bytes32 blockHash
    ); // Sự kiện khi thêm sản phẩm

    event ProductUpdated(string indexed id, string name, string price); // Sự kiện khi cập nhật sản phẩm

    // Thêm sản phẩm mới với ID từ backend
    function addProduct(
        string memory _id,
        string memory _name,
        string memory _description,
        string memory _price, // Thay đổi kiểu giá thành string
        uint256 _quantity,
        string memory _brand, // Thêm brand vào tham số
        string memory _category, // Thêm category vào tham số
        string memory _size, // Thêm size vào tham số
        string memory _status,
        string memory _store,
        string[] memory _cids
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
            _brand, // Lưu brand
            _category, // Lưu category
            _size, // Lưu size
            _status,
            _store, // Đặt mặc định cho store là "onchain"
            _cids,
            msg.sender // Lưu địa chỉ ví của người tạo
        );

        // Lưu ID vào mảng productIds
        productIds.push(_id);

        // Phát sự kiện khi thêm sản phẩm
        emit ProductAdded(_id, _name, _price, blockhash(block.number));
    }

    // Cập nhật thông tin sản phẩm
    function updateProduct(
        string memory _id, // Sửa đổi kiểu ID thành string
        string memory _name,
        string memory _description,
        string memory _price, // Thay đổi kiểu giá thành string
        uint256 _quantity,
        string memory _brand, // Thêm brand vào tham số
        string memory _category, // Thêm category vào tham số
        string memory _size, // Thêm size vào tham số
        string memory _status,
        string memory _store,
        string[] memory _cids
    ) public {
        require(bytes(products[_id].id).length != 0, "Product not found"); // Kiểm tra sản phẩm có tồn tại hay không

        // Cập nhật sản phẩm
        products[_id] = Product(
            _id,
            _name,
            _description,
            _price,
            _quantity,
            _brand, // Cập nhật brand
            _category, // Cập nhật category
            _size, // Cập nhật size
            _status,
            _store, // Giữ nguyên store không thay đổi
            _cids,
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
            string memory price, // Cập nhật kiểu giá thành string
            uint256 quantity,
            string memory brand, // Thêm brand vào trả về
            string memory category, // Thêm category vào trả về
            string memory size, // Thêm size vào trả về
            string memory status,
            string memory store, // Thêm store vào trả về
            string[] memory cids,
            address creator
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
            p.brand,
            p.category,
            p.size,
            p.status,
            p.store,
            p.cids,
            p.creator
        );
    }

    // Lấy tất cả sản phẩm
    function getAllProducts() public view returns (Product[] memory) {
        Product[] memory allProducts = new Product[](productIds.length);

        for (uint256 i = 0; i < productIds.length; i++) {
            allProducts[i] = products[productIds[i]];
        }
        return allProducts;
    }
}
