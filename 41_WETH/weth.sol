// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20 {
    //存款
    event deposit(address indexed dst,uint wad);
    //取款
    event withdrawal(address indexed src,uint wad);
    constructor() ERC20("WETH","WETH") {

    }
    fallback() external payable {
        depo();
    }
     receive() external payable {
        depo();
    }
    function depo() public payable {
        _mint(msg.sender,msg.value);
        emit deposit(msg.sender, msg.value);
    }
    function withdraw(uint amount) public {
        require(balanceOf(msg.sender)>=amount);
        _burn(msg.sender,amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
        emit withdrawal(msg.sender,amount);
    }
}