// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArcadeManager is Initializable, UUPSUpgradeable, Ownable{
    
    address payable public manager;
    mapping (address => uint32) shares;
    address [] public holders;
    uint256 public length = holders.length;

    function initialize(address payable _manager) public initializer {
        manager = _manager;
   }

   function _authorizeUpgrade(address) internal override onlyOwner {}

   function addShares(address _o, uint32 _shares) external onlyOwner {
       holders.push(_o);
       shares[_o] = _shares;
   } 

   modifier onlyAuthorized() {
       _;
   }

   function findIndex(address _f) internal view returns (uint256 ret) {
    address[] memory replica = holders;
       for (uint256 i = 0; i < replica.length; i++) {
           if (replica[i] == _f) {
               return i;
           }
       }
   } 

   function removeShare(address _o) external onlyOwner returns (bool b){
       if (length == 0) return false;
       uint256 find = findIndex(_o);
        for (uint i = find; i<holders.length-1; i++){
            holders[i] = holders[i+1];
        }
        delete holders[holders.length-1];
        return true;
   }

   function checkManager(address _o) external view returns (bool) {
       address convert = address(manager);
       if (_o == convert) {
           return true;
       } 
       return false;
   }

}
