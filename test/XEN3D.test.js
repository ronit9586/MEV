// Import necessary modules from Hardhat
const { expect } = require("chai");
const { formatUnits, parseUnits } = require("ethers/lib/utils");
const { ethers } = require("hardhat");

// Describe the contract and its tests
describe("Xen3D Contract", function () {
    let Xen; // Store the contract factory
    let xen; // Store the contract factory
    let Xen3D; // Store the contract factory
    let xen3d; // Store the deployed contract instance
    let XENDoge; // Store the contract factory
    let xENDoge; // Store the deployed contract instance
    let owner, addr1, addr2; // Store the contract deployer's address
    const nullAddress = "0x0000000000000000000000000000000000000000";
    before(async () => {
        // Get the contract factory and deploy the contract
        [owner,addr1 ] = await ethers.getSigners(); 
        Xen = await ethers.getContractFactory("XENCrypto");
        xen = await Xen.deploy();
        XENDoge = await ethers.getContractFactory("XENDoge");
        xENDoge = await XENDoge.deploy();
        Xen3D = await ethers.getContractFactory("Xen3D");
        xen3d = await Xen3D.deploy(xen.address, xENDoge.address);
    });

    const buyingPrice = async () => {
        const oneToken = parseUnits("1", 18);
        const xenToToken = await xen3d.xenToTokens_(oneToken);
        return formatUnits(xenToToken, 18);
    }

    const sellingPrice = async () => {
        const oneToken = parseUnits("1", 18);
        const xenToToken = await xen3d.tokensToXEN_(oneToken);
        return formatUnits(xenToToken, 18);
    }

    const xenToTokens_ = async (amount) => {
        const price = await xen3d.xenToTokens_(amount);
        return formatUnits(price, 18);
    }

    const tokensToXEN_ = async (amount) => {
        const price = await xen3d.tokensToXEN_(amount);
        return formatUnits(price, 18);
    }

    const xenBalance = async (address) => {
        const balanceOfXen = await xen.balanceOf(address);
        return formatUnits(balanceOfXen, 18);
    }

    const myDividends = async (address) => {
        const balanceOfXen = await xen3d.myDividends(false);
        return formatUnits(balanceOfXen, 18);
    }

    const xen3dBalance = async (address) => {
        const balanceOfXen = await xen3d.balanceOf(address);
        return formatUnits(balanceOfXen, 18);
    }
    
    it("Buy Price", async () => {
        const price = await buyingPrice();
        console.log(`Buying Price ${price} Xen3d  require for 1 Xen`);
    })
    
    it("Buy", async function () {
        const amountToBuy = parseUnits("10", 18);
        await xen.connect(owner).approve(xen3d.address, amountToBuy);  
        await xen3d.buy(addr1.address, amountToBuy);
        // console.log(formatUnits(await xen3d.purchaseTokens(amountToBuy, nullAddress), 18));
        console.log("Xen Purchased", await xen3dBalance(owner.address))
    }); 
    
    it("Selling Price", async () => {
        const price = await sellingPrice();
        console.log(`Selling Price ${price} Xen3d require for 1 Xen`);
    })


    it("Sell Token", async function () {
        const amountToBuy = parseUnits("500", 18);
        // await xen3d.sell(amountToBuy);
        console.log("Xen Balance Before:", await myDividends(owner.address))
        await xen3d.withdraw();
        console.log("Xen Balance After:", await xenBalance(owner.address))
    }); 

    it("reinvest Token", async function () {
        const amountToBuy = parseUnits("41000", 18); 
        console.log("Xen Balance Before:", await myDividends(owner.address))
        await xen3d.reinvest();
        await xen3d.sell();
        await xen3d.withdraw();
        console.log("Xen Balance After:", await xenBalance(owner.address))
    }); 
    
});