const {ethers, upgrades} = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    const {save} = deployments;

    // Deploy the NFTAuction contract
    const NFTAuction = await ethers.getContractFactory("NFTAuction");
    console.log("Deploying NFTAuction...");
    //部署可升级合约
    const nftAuction = await upgrades.deployProxy(NFTAuction, [], { initializer: 'initialize', kind: 'uups' });
    await nftAuction.waitForDeployment();
    const nftAuctionAddress = await nftAuction.getAddress();
    console.log("NFTAuction deployed to:", nftAuctionAddress);
    //实现合约地址
    const implementationAddress = await upgrades.erc1967.getImplementationAddress(nftAuction.target);
    console.log("Implementation Address:", implementationAddress);

    //写入部署信息到文件
    const storage = path.resolve(__dirname, `./.cache/NFTAuction.json`);
    fs.writeFileSync(
        storage,
        JSON.stringify(
            {
                address: nftAuctionAddress,
                implementationAddress: implementationAddress,
                abi: NFTAuction.interface.format("json")
            })
    );  


    // Save the deployment info
    await save("NFTAuction", {
        address: nftAuctionAddress,
        abi: NFTAuction.interface.format("json")
    });
}

module.exports = main;

module.exports.tags = ["NFTAuction"];