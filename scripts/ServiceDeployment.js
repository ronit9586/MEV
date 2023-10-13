// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { parseUnits } = require("ethers/lib/utils");
const hre = require("hardhat");

async function main() {
  let MaaLaxmiToken, maaLaxmiToken, owner, addr1, addr2;  
  MaaLaxmiToken = await ethers.getContractFactory("MaaLaxmiToken"); 

  [owner, addr1, addr2] = await ethers.getSigners();
  maaLaxmiToken = await MaaLaxmiToken.attach("0x9Fe57112618e3855a103ecdb4206D4c75bA904C9"); 

  const Service = await ethers.getContractFactory("Service");
  const service = await Service.deploy(maaLaxmiToken.address);
  console.log("Service Address: ", service.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
