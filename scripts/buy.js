
const { parseUnits } = require("ethers/lib/utils");
const hre = require("hardhat");

async function main() {

    [owner, addr1, addr2] = await ethers.getSigners();
    // Deploy Presale contract
    const usdtAmount = parseUnits("10", 6)
    const USDT = await ethers.getContractFactory("USDT");
    const usdtInstance = await USDT.attach("0xaAc932cDBa9A04624153d0219a6b7cBF4749127B")
    const txApprove = await usdtInstance.approve("0xE7Da61159a5d85E40Bfe3437656Ee2a06e1B9549", usdtAmount);
    await txApprove.wait()
    const Presale = await ethers.getContractFactory("Presale2");
    const presaleInstance = await Presale.attach("0xE7Da61159a5d85E40Bfe3437656Ee2a06e1B9549")
    // console.log(await usdtInstance.balanceOf(owner.address).)
    const tx2 = await presaleInstance.buyWithUSDT(usdtAmount);
    // const tx = await presaleInstance.buy({ value: 1000 });
    console.log(tx);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
