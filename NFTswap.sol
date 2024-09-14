// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "34_ERC721/WTFAPE.sol";
import "34_ERC721/IERC721Receiver.sol";
import "34_ERC721/IERC721.sol";

contract NFTswap is IERC721Receiver {
    event List(
        address indexed seller,
        address indexed nftaddr,
        uint256 indexed tokenid,
        uint256 price
    );
    event Purchase(
        address indexed buyer,
        address indexed nftaddr,
        uint256 indexed tokenid,
        uint256 price
    );
    event Revoke(
        address indexed seller,
        address indexed nftaddr,
        uint256 indexed tokenid
    );
    event Update(
        address indexed seller,
        address indexed nftAddr,
        uint256 indexed tokenId,
        uint256 newPrice
    );
    struct Order{
        address owner;
        uint256 price;
    }
    mapping (address => mapping (uint256 => Order)) public nftList;
    receive() external payable { }
    fallback() external payable {}
    //挂单
    function list(address _nftaddr,uint256 _tokenid,uint256 _price) public  {
        IERC721 nft = IERC721(_nftaddr);
        require(nft.getApproved(_tokenid) == address(this));
        require(_price>0);
        Order storage order = nftList[_nftaddr][_tokenid];
        order.owner = msg.sender;
        order.price = _price;
        nft.safeTransferFrom(msg.sender, address(this), _tokenid);
        emit List(msg.sender, _nftaddr, _tokenid, _price);
    }
    //撤单
    function revoke(address _nftaddr,uint256 tokenid) public {
        Order storage order = nftList[_nftaddr][tokenid];
        require(order.owner == msg.sender);
        IERC721 nft = IERC721(_nftaddr);
        require(nft.ownerOf(tokenid) == address(this));
        nft.safeTransferFrom(address(this), msg.sender, tokenid);
        delete nftList[_nftaddr][tokenid];
        emit Revoke(msg.sender, _nftaddr, tokenid);
    }
    //改价
    function updata(address _nftaddr,uint256 _tokenid,uint256 newprice) public {
        require(newprice>0);
        Order storage order = nftList[_nftaddr][_tokenid];
        require(order.owner == msg.sender);
        IERC721 nft = IERC721(_nftaddr);
        require(nft.ownerOf(_tokenid) == address(this));
        order.price = newprice;
        emit Update(msg.sender, _nftaddr, _tokenid, newprice);
    }
    //购买
    function purchase(address _nftaddr,uint256 _tokenid) payable public {
        Order storage order = nftList[_nftaddr][_tokenid];
        require(order.price>0);
        require(msg.value>=order.price);
        IERC721 nft = IERC721(_nftaddr);
        require(nft.ownerOf(_tokenid) == address(this));
        nft.safeTransferFrom(address(this), msg.sender, _tokenid);
        payable(order.owner).transfer(order.price);
        //找钱
        payable(msg.sender).transfer(msg.value - order.price);
        delete nftList[_nftaddr][_tokenid];
        emit Purchase(msg.sender, _nftaddr, _tokenid, order.price);
    } 
     // 实现{IERC721Receiver}的onERC721Received，能够接收ERC721代币
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenid,
        bytes calldata data
    ) external  override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}