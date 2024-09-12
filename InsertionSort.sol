// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract InsertionSort{
    function insertSort(uint[] memory arr) public pure returns (uint[] memory) {
        for(uint i = 1;i<arr.length;i++){
            uint j = i;
            uint temp = arr[i];
            while(j>=1&&temp<arr[j-1]){
                arr[j] = arr[j-1];
                j--;
            }
            arr[j] = temp;
        }
        return arr;
    }
}