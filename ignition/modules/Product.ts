import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("Product", (m) => {
  // Deploy the ProductManager contract
  const productManager = m.contract("ProductManager", [
  ]);

  return { productManager };
});

