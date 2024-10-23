import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("Product", (m) => {
  const productRegistry = m.contract("ProductRegistry"); // Đảm bảo rằng bạn đã cung cấp tên hợp đồng đúng

  // Thêm sản phẩm mới
  // m.call(productRegistry, "addProduct", [
  //   "Tên sản phẩm",        // _name
  //   "Mô tả sản phẩm",      // _description
  //   100,                   // _price
  //   10,                    // _quantity
  //   "Còn hàng",           // _status
  //   "https://ipfs.io/ipfs/exampleCID" // _ipfsUrl
  // ]);

  // Cập nhật sản phẩm
  // m.call(productRegistry, "updateProduct", [
  //   1,                     // _id
  //   "Tên sản phẩm mới",    // _name
  //   "Mô tả sản phẩm mới",  // _description
  //   150,                   // _price
  //   5,                     // _quantity
  //   "Hết hàng",           // _status
  //   "https://ipfs.io/ipfs/newExampleCID" // _ipfsUrl
  // ]);

  // Lấy thông tin sản phẩm
  //m.call(productRegistry, "getProduct", [1]);

  // Lấy tổng số sản phẩm
  //m.call(productRegistry, "getTotalProducts");

  return { productRegistry }; // Trả về contract để sử dụng sau này
});
