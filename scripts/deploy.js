// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { parseUnits, formatUnits } = require("ethers/lib/utils");
const hre = require("hardhat");

async function main() {
  let MaaLaxmiToken, maaLaxmiToken, USDT, USDTToken, Presale, presale, owner, addr1, addr2;
  let startTime, endTime;
  const Month = 60*15;
  const millonPow = 5;
  MaaLaxmiToken = await ethers.getContractFactory("MaaLaxmiToken");
  USDTToken = await ethers.getContractFactory("USDT");

  [owner, addr1, addr2] = await ethers.getSigners();
  maaLaxmiToken = await MaaLaxmiToken.deploy();
  await maaLaxmiToken.deployed();
  USDT = await USDTToken.deploy();
  await USDT.deployed();
  console.log("Maa Laxmi Token Address: ", maaLaxmiToken.address)
  console.log("USDT Address: ", USDT.address)


  // Deploy Presale contract
  Presale = await ethers.getContractFactory("Presale2");
  startTime = Math.floor(Date.now() / 1000);
  endTime = startTime + 4 * Month; // 4 months later 
  console.log(startTime, endTime);
  presale = await Presale.deploy(USDT.address, maaLaxmiToken.address, startTime, endTime);
  await presale.deployed();
  console.log(formatUnits(await maaLaxmiToken.balanceOf(owner.address), 18));
  await maaLaxmiToken.transfer(presale.address, parseUnits("750", 18 + millonPow));
  console.log("Presale2 Address: ", presale.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
