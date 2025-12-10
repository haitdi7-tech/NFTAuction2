// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import "./NFTAuction.sol";

contract NFTAuctionV2 is NFTAuction {
    // 新增功能：获取拍卖详情
    function getAuctionDetails(uint256 auctionId) external view returns (Auction memory) {
        return auctions[auctionId];
    }

}