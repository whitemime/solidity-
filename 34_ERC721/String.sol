// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
library Strings{
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns(string memory){
        if (value == 0){
            return "0";
        }
        uint256 temp = value;
        uint256 digit;
        while(temp!=0){
            digit++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digit);
        while(value != 0){
            digit--;
            //48为数字0的ASCII码 变成字符 确保为8位无符号整型 再变成字节
            buffer[digit] = bytes1(uint8(48+uint256(value%10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory){
        if (value == 0){
            return "0x00";
        }
        uint256 temp = value;
        uint256 digit;
        while(temp != 0){
            digit++;
            temp>>=8;
        }
        return toHexString(value, digit);  
    }
    function toHexString(uint256 value,uint256 length) internal pure returns (string memory){
        bytes memory buffer = new bytes(length * 2 + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2*length+1;i>1;i--){
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value>>=4;
        }
        require(value == 0,"Strings: hex length insufficient");
        return string(buffer);
    }
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}