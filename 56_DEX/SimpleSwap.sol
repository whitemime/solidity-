// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract SimpleSwap is ERC20{
    //交易所提供的两种代币
    IERC20 public token0;
    IERC20 public token1;
    //两种代币余额
    uint public resvers0;
    uint public resvers1;
    //铸造代币事件  返还给流动性提供者
    event Mint(address indexed sender,uint amount0,uint amount1);
    //销毁
    event Burn(address indexed sender,uint amount0,uint amount1);
    //普通交易
    event Swap(address indexed sender,uint amountIn,address tokenIn,uint amountOut,address tokenOut);
    //设置两个代币
    constructor(IERC20 _token0,IERC20 _token1) ERC20("SimpleSwap", "SS") {
        token0 = _token0;
        token1 = _token1;
    }
    function min(uint x,uint y) internal pure returns(uint z) {
        z = x > y ? y : x ;
    } 
    function sqrt(uint y)  internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = (y / 2) + 1;
            while (x < z) {
                z = x;
                x = ((y / x) + x) / 2;
            } 
        }else if (y != 0) {
            z = 1; 
        }
    }
    //添加流动性
    function addLiquidity(uint amount0Desired,uint amount1Desired) public returns(uint liquidity) {
        //用户给合约授权转账
        token0.transferFrom(msg.sender, address(this), amount0Desired);
        token1.transferFrom(msg.sender, address(this), amount1Desired);
        uint _totalSupply = totalSupply();
        //提供流动份额
        if (_totalSupply == 0) {
            liquidity = sqrt(amount0Desired*amount1Desired);
        }else {
            liquidity = min(amount0Desired * _totalSupply / resvers0, amount1Desired * _totalSupply / resvers1);
        }
        require(liquidity > 0);
        resvers0 = token0.balanceOf(address(this));
        resvers1 = token1.balanceOf(address(this));
        _mint(msg.sender, liquidity);
        emit Mint(msg.sender, amount0Desired, amount1Desired);
    }
    //移除流动性
    function removeLiquidity(uint liquidity) external returns(uint amount0,uint amount1) {
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));
        uint _totalSupply = totalSupply();
        //销毁流动份额
        amount0 = liquidity * balance0 / _totalSupply;
        amount1 = liquidity * balance1 / _totalSupply;
        require(amount0 > 0 && amount1 >0);
        _burn(msg.sender, liquidity);
        token0.transfer(msg.sender, amount0); 
        token1.transfer(msg.sender, amount1);
        resvers0 = token0.balanceOf(address(this));
        resvers1 = token1.balanceOf(address(this));
        emit Burn(msg.sender, amount0, amount1);
    }
    //假设用amountin数量的其中一种代币换取另一种代币 返回另一种代币的数量
    function getAmountOut(uint amountIn,uint reserveIn,uint reserveOut) public pure returns(uint amountOut) {
        require(amountIn > 0);
        require(reserveIn > 0 && reserveOut > 0);
        amountOut = amountIn * reserveOut / (reserveIn + amountIn);
    }
    function swap(uint amountIn,IERC20 tokenIn,uint amountOutMin) external returns(uint amountOut,IERC20 tokenOut) {
        require(amountIn > 0);
        require(tokenIn == token0 || tokenIn == token1);
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));
        if (tokenIn == token0) {
            tokenOut = token1;
            amountOut = getAmountOut(amountIn, balance0, balance1);
            require(amountOut > amountOutMin);
            tokenIn.transferFrom(msg.sender,address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }else {
            tokenIn = token1;
            amountOut = getAmountOut(amountIn, balance1, balance0);
            require(amountOut > amountOutMin);
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            tokenOut.transfer(msg.sender, amountOut);
        }
        resvers0 = token0.balanceOf(address(this));
        resvers1 = token1.balanceOf(address(this));
        emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
    }
}