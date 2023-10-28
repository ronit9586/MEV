// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { formatUnits, parseUnits } = require("ethers/lib/utils");
const hre = require("hardhat");

async function main() {
  
  const MultiSwap = await ethers.getContractFactory("MultiSwap"); 

  [owner, addr1, addr2] = await ethers.getSigners();
  const multiSwap = await MultiSwap.deploy();
  await multiSwap.deployed(); 
  console.log(`owner: ${owner.address}`);
  await multiSwap.multiSwap("0x07865c6E87B9F70255377e024ace6630C1Eaa37F", "1", 2, {value: parseUnits("1", 9)})
  console.log("multiSwap Address: ", multiSwap.address) 
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
