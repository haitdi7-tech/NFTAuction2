// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
 contract MyNFT is ERC721URIStorage, Ownable {
    string private _tokenURI;

    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender){}

    function mint(address to,uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        //(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
       return _tokenURI;
    }

    function setTokenURI(string memory uri) external onlyOwner {
        _tokenURI = uri;
    }
 }