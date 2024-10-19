// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// Khai báo giá trị mặc định cho các tham số
const DEFAULT_CID = "QmSomeDefaultCID"; // CID mặc định (nếu cần)
const INITIAL_LOCKED_AMOUNT: bigint = 0n; // Không cần gửi Ether khi triển khai

const StorageModule = buildModule("StorageModule", (m) => {
  // Lấy các tham số từ cấu hình module
  const cid = m.getParameter("cid", DEFAULT_CID);
  const lockedAmount = m.getParameter("lockedAmount", INITIAL_LOCKED_AMOUNT);

  // Triển khai smart contract `Storage`
  const storage = m.contract("Storage", [], {
    value: lockedAmount, // Nếu bạn muốn gửi Ether khi triển khai
  });

  // Trả về đối tượng contract để sử dụng
  return { storage };
});

export default StorageModule;
