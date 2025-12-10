// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "hardhat/console.sol";

contract NFTAuction is Initializable, UUPSUpgradeable {
    // Auction contract code goes here
    struct Auction {
        //NFT合约地址
        address nftAddress;
        // NFT的tokenId
        uint256 tokenId;
        // 卖家地址
        address seller;
        // 起拍价
        uint256 startingBid;
        // 最高出价
        uint256 highestBid;
        // 最高出价者
        address highestBidder;
        // 拍卖是否结束
        bool isEnd;
        // 拍卖持续时间
        uint256 duriation;
        // 拍卖开始时间
        uint256 startTime;
        //资产类型
        address assetAddress;
    }

    mapping(uint256 => Auction) public auctions;
    uint256 NextAuctionId;
    address public admin;

    mapping(address =>  AggregatorV3Interface) public priceFeeds;

    //初始化函数
    function initialize() public initializer {
        admin = msg.sender;
    }

    function _authorizeUpgrade(address newImplementation) internal  override{
        require(msg.sender == admin, "Only admin can upgrade");
    }

    // constructor() {
    //     admin = msg.sender;
    // }

    function createAuction(
        uint256 startPrice,
        uint256 _duration,
        address _tokenAddress,
        uint256 _amount
    ) external {
        //检查输入起拍价格
        require(startPrice > 0, "Starting bid must be greater than zero");
        //检查拍卖持续时间
        require(_duration > 0, "Duration must be greater than zero");
        //ERC721转币到拍卖合约
        IERC721(_tokenAddress).safeTransferFrom(msg.sender,address(this),_amount);
        auctions[NextAuctionId] = Auction({
            nftAddress: _tokenAddress,
            tokenId: _amount,
            seller: msg.sender,
            startingBid: startPrice,
            highestBid: 0,
            highestBidder: address(0),
            isEnd: false,
            duriation: _duration,
            startTime: block.timestamp,
            assetAddress: address(0)
        });
        NextAuctionId++;
    }

    function plaseBid(
        uint256 auctionId,
        uint256 amount,
        address _bidAddress
    ) external payable {
        Auction storage auction = auctions[auctionId];
        // 检查拍卖是否进行中
        require(
            block.timestamp < auction.startTime + auction.duriation,
            "Auction has ended"
        );
        //根据地址类型换成统一尺度比价
        uint256 pauValue;
         int256 eth2usd;
         int256 usdc2usd ;
        if (_bidAddress == address(0)) {
            eth2usd = getLatestPrice(address(0));
            amount = msg.value;
            pauValue = amount * uint256(eth2usd) / 1e18;
            
        } else {
            usdc2usd = getLatestPrice(_bidAddress);
            uint256 price = uint256(getLatestPrice(_bidAddress));
            pauValue = amount * price / 1e18;
            
        }
        console.log("eth2usd :", uint256(eth2usd));
        console.log("usdc2usd:",uint256(usdc2usd));
        uint256 startPrice = auction.startingBid * uint256(getLatestPrice(_bidAddress)) / 1e18;
        uint256 highestBid = auction.highestBid * uint256(getLatestPrice(_bidAddress)) / 1e18;

        //console.log("eth2usd:",eth2usd);
        console.log("_bidAddress:",_bidAddress);
        console.log("startPrice:",startPrice);
        console.log("highestBid:",highestBid);
        console.log("pauValue:",pauValue);
        require(
            pauValue >= startPrice && pauValue > highestBid,
            "Bid amount is too low"
        );
        //转移ERC20代币
        if (_bidAddress != address(0)) {
            console.log("IERC20(balanceOf)",IERC20(_bidAddress).balanceOf(msg.sender));
            console.log("transferbalanceOf",IERC20(_bidAddress).balanceOf(address(this)));
            console.log("amount",amount);
            require(IERC20(_bidAddress).transferFrom(msg.sender, address(this), amount), "ERC20 transfer failed");
            console.log("IERC20(balanceOf)22",IERC20(_bidAddress).balanceOf(msg.sender));
            console.log("address(this)22",address(this));
            console.log("transferbalanceOf22",IERC20(_bidAddress).balanceOf(address(this)));
            console.log("amount22",amount);
        }
        //退还之前的最高出价者
        console.log("highestBidderamount22",auction.highestBidder);
        if (auction.highestBidder != address(0)) {
            //转移ERC20代币
            if (auction.assetAddress != address(0)) {
                console.log("_bidAddressamount22",auction.assetAddress );
                require(IERC20(auction.assetAddress ).transfer(auction.highestBidder, auction.highestBid), "ERC20 transfer failed");
            } else {
                
                payable(auction.highestBidder).transfer(auction.highestBid);
            }
        }

        //更新最高出价和最高出价者
        auction.highestBid = amount;
        auction.highestBidder = msg.sender;     
        auction.assetAddress = _bidAddress;
    }

    //结束拍卖
    function endAuction(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        //检查拍卖是否已经结束
        require(
            block.timestamp >= auction.startTime + auction.duriation,
            "Auction is still ongoing"
        );
        require(!auction.isEnd, "Auction has already ended");
        auction.isEnd = true;
        //将NFT转移给最高出价者
        if (auction.highestBidder != address(0)) {
            IERC721(auction.nftAddress).safeTransferFrom(
                address(this),
                auction.highestBidder,
                auction.tokenId
            );

            //  (bool success, ) = payable(auction.seller).call{value: auction.highestBid}("");
            //  require(success, " transfer fail");
            //将最高出价转移给卖家
            if (auction.assetAddress != address(0)) {
                 console.log("IERC20(_bidAddress)",IERC20(auction.assetAddress).balanceOf(msg.sender));
                console.log("transfer",IERC20(auction.assetAddress).balanceOf(auction.seller));
                console.log("sender",msg.sender);
                console.log("address(this)",address(this));
                 console.log("balanceOfaddress(this)",IERC20(auction.assetAddress).balanceOf(address(this)));
                require(IERC20(auction.assetAddress).transfer(auction.seller, auction.highestBid), "ERC20 transfer failed");
            } else {
                payable(auction.seller).transfer(auction.highestBid);
            }
        } else {
            //如果没有出价，NFT归还给卖家
            // IERC721(auction.nftAddress).transferFrom(
            //     address(this),
            //     auction.seller,
            //     auction.tokenId
            // );
        }
    }


    
    function getLatestPrice(address _priceFeed) public view returns (int256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);
        AggregatorV3Interface priceFeed = priceFeeds[_priceFeed];
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    //设置喂价器地址
    function setPriceFeed(address _asset, address _priceFeed) external {
        priceFeeds[_asset] = AggregatorV3Interface(_priceFeed); 
        }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
