const {ethers, upgrades} = require("hardhat");
const path = require("path");
const fs = require("fs");

async function main() {
    const {save} = deployments;
    //读入部署信息
    const storePath = path.resolve(__dirname, `./.cache/NFTAuction.json`);
    const {address ,abi} = JSON.parse(fs.readFileSync(storePath, 'utf8'));
    //获取将要升级合约实例
    const NftAuctionV2 = await ethers.getContractFactory("NFTAuctionV2");
    const nftAuctionV2 = await upgrades.upgradeProxy(address, NftAuctionV2);
    await nftAuctionV2.waitForDeployment();
    const v2Address = await nftAuctionV2.getAddress();
    console.log("NFTAuction upgraded at:", v2Address);
    
    await save("NFTAuctionUpgrade", {
        address: v2Address,
        abi: NftAuctionV2.interface.format("json")
    });
}

module.exports = main;

module.exports.tags = ["NFTAuctionUpgrade"];