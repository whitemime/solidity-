// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "34_ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DutchAuction is ERC721,Ownable{
    uint256 public constant COLLECTION_SIZE = 10000;//NFT总数
    uint256 public constant AUCTION_START_PRICE = 1 ether;//起拍价
    uint256 public constant AUCTION_END_PRICE = 0.1 ether;//结束价(最低价)
    uint256 public constant AUCTION_TIME = 10 minutes;//拍卖时长
    uint256 public constant AUCTION_DROP_INTERVAL = 1 minutes;//过多长时间价格减少一次
    uint256 public constant AUCTION_DROP_PER_STEP = 
    (AUCTION_START_PRICE - AUCTION_END_PRICE) / (AUCTION_TIME / AUCTION_DROP_INTERVAL);//每次价格衰减多少
    uint256 public auctionStartTime;
    string private _baseTokenURI;   // tokenuri的前缀
    uint256[] private _allTokens; // 记录所有存在的tokenId
    //设置起拍时间 项目方也可以通过函数设置
     constructor() Ownable(msg.sender) ERC721("WTF Dutch Auction", "WTF Dutch Auction") {
        auctionStartTime = block.timestamp;
    } 
    function setAuctionStartTime(uint32 timestamp) external onlyOwner {
        auctionStartTime = timestamp;  // 设置起拍时间
    }
    function totalSupply() public view virtual returns(uint256) {return _allTokens.length;}
    function _addTokenToAllTokensEnumeration(uint256 tokenid) private  { _allTokens.push(tokenid);}
    //获取拍卖实时价格 通过当前区块时间及拍卖相关变量来计算
    function getAuctionPrice() public view returns(uint256) {
        if (block.timestamp < auctionStartTime) {
            return AUCTION_START_PRICE;
        }else if (block.timestamp - auctionStartTime >= AUCTION_TIME) {
            return AUCTION_END_PRICE;
        }else {
            uint256 steps = (block.timestamp - auctionStartTime) / AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }
    //用户拍卖时购买NFT
    //传入铸造的NFT数量
    function auctionMint(uint256 amount) external payable {
        //省gas设置局部变量 检查是否设置开始时间和必须在开始后交易
        uint256 _saleStartTime = uint256(auctionStartTime);
        require(_saleStartTime !=0 && block.timestamp >= _saleStartTime);
        //检查是否超过最大供应量 amount为用户想买的 total为已铸造的 size为项目方最多卖的数量
        require(amount + totalSupply() <= COLLECTION_SIZE);
        //计算用户应该给的钱 检查钱够不够
        uint256 totalCost = getAuctionPrice()*amount;
        require(msg.value >= totalCost);
        //铸造NFT 每个NFT的tokenid为存tokenid数组的长度
        for(uint i = 0;i < amount;i++) {
            uint256 mintToken = totalSupply();
            _mint(msg.sender, mintToken);
            _addTokenToAllTokensEnumeration(mintToken);
        }
        if (msg.value > totalCost) {
            (bool success, ) = payable(msg.sender).call{value:msg.value - totalCost}("");
            require(success);
        }
    }
    //项目方提款
    function withdrawMoney() external {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
     // BaseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    // BaseURI setter函数, onlyOwner
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }  
}