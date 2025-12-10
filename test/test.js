const {ethers,deployments} = require("hardhat");
const {expect} = require("chai");

describe("Auction Test", () => {
    it("Create ", async() => {
        const [signer, buyer] = await ethers.getSigners()
        // 1 一键部署拍卖合约
        await deployments.fixture(["NFTAuction"]);
        //返回合约地址
        const nftAuctionDeployment = await deployments.get("NFTAuction");
        //通过地址获取合约实例
        const nftAuction = await ethers.getContractAt("NFTAuction", nftAuctionDeployment.address);

        // 2部署721合约
        const NFT = await ethers.getContractFactory("MyNFT");
        const nft = await NFT.deploy();
        await nft.waitForDeployment();
        const nftAddress = await nft.getAddress();
        console.log("NFT deployed to:", nftAddress);
        // 铸造NFT
        await nft.mint(signer.address, 1);
        console.log("NFT minted to:", signer.address);

        //授权给拍卖合约
        //await nft.approve(nftAuctionDeployment.address, tokenId);
        nft.setApprovalForAll(nftAuctionDeployment.address, true);
        console.log("NFT approved to Auction contract");

        //3 部署USDC合约
        const Usdc = await ethers.getContractFactory("MyERC20");
        const usdc = await Usdc.deploy();
        await usdc.waitForDeployment();
        const UsdcAddress = await usdc.getAddress();
        console.log("USDC deployed to:", UsdcAddress);
        //给买家铸造USDC
        await usdc.mint(buyer.address, ethers.parseEther("1000"));
        //usdc.transfer(buyer,ethers.parseEther("1000"));
        const bl = await usdc.balanceOf(buyer);
        console.log("USDC minted to buyer:", buyer.address);
        //授权给拍卖合约
        console.log("USDC of buyer:", bl);
        await usdc.connect(buyer).approve(nftAuctionDeployment.address, ethers.parseEther("500")); 
        
        // 4设置价格预言机地址

        const aggreagatorV3 = await ethers.getContractFactory("AggreagatorV3");
        const priceFeedEthDepoly = await aggreagatorV3.deploy(8,101);
        const priceFeedEth  =  await priceFeedEthDepoly.waitForDeployment();
        const priceFeedEthAddress = priceFeedEth.getAddress();
        console.log("ethfeed:",priceFeedEthAddress);

        const priceFeedUSDCDepoly = await aggreagatorV3.deploy(8,100);
        const priceFeedUsdc = await priceFeedUSDCDepoly.waitForDeployment();
        const priceFeedUsdcAddress = await priceFeedUsdc.getAddress();
        console.log("usdcFeed:",priceFeedEthAddress);
        
        
        const token2Usd = [{
        token: ethers.ZeroAddress,
        priceFeed: priceFeedEthAddress
        }, {
        token: UsdcAddress,
        priceFeed: priceFeedUsdcAddress
        }];

        for (let i = 0; i < token2Usd.length; i++) {
            const { token, priceFeed } = token2Usd[i];
            await nftAuction.setPriceFeed(token, priceFeed);
        }

        //5.创建拍卖
        const ERC20Address = UsdcAddress;
        const bidAmount = ethers.parseEther("3");
        // NFT的tokenID
        const tokenId = 1;
        await nftAuction.createAuction(
            ethers.parseEther("1"), // Starting bid
             12 , // Duration:  12s
            nftAddress, // NFT contract address
            tokenId, // Token ID        
        );
        console.log("Auction created");

        const auction = await nftAuction.auctions(0);
        console.log("Auction details:", auction);

        //升级合约
        await deployments.fixture(["NFTAuctionUpgrade"]);
        const nftAuctionV2Deployment = await deployments.get("NFTAuctionUpgrade");
        const nftAuctionV2 = await ethers.getContractAt("NFTAuctionV2", nftAuctionV2Deployment.address);
        const auctionV2 = await nftAuctionV2.auctions(0);
        console.log("Auction V2 details:", auctionV2);
        //升级后状态期望一致
        expect(auction.nftAddress).to.equal(auctionV2.nftAddress);

        // const hello = await nftAuctionV2.hello();
        // console.log("Hello from V2:", hello);
        //购买者出价 eth参加
        await nftAuctionV2.connect(buyer).plaseBid(0, 0,ethers.ZeroAddress,{ value: ethers.parseEther("2.1") });
        console.log("Bid placed by buyer:", buyer.address);
        
        //买家出价
        await nftAuctionV2.connect(buyer).plaseBid(0, ethers.parseEther("2.11"),ERC20Address);
        console.log("Bid placed by buyer with ERC20 tokens:", buyer.address);

        //等待拍卖结束
        console.log("Waiting for auction to end...");
        await new Promise(resolve => setTimeout(resolve, 13000)); //等待13秒
        //结束拍卖
        await nftAuctionV2.endAuction(0);
        console.log("Auction ended");

        //获取拍卖结果
        const finalAuction = await nftAuctionV2.auctions(0);
        console.log("Final Auction details:", finalAuction);
        
        expect(finalAuction.highestBidder).to.equal(buyer.address);
        //验证NFT归属
        const newOwner = await nft.ownerOf(tokenId);
        console.log("New NFT owner:", newOwner);
        expect(newOwner).to.equal(buyer.address);
    });
});