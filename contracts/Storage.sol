// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract Storage {
    mapping(address => string) private cids;

    // Lưu CID vào mapping
    function storeCID(string memory cid) public {
        cids[msg.sender] = cid;
    }

    // Lấy CID của một địa chỉ
    function getCID(address user) public view returns (string memory) {
        return cids[user];
    }
}
