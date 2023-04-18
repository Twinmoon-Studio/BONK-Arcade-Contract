// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/arcades/ArcadeManager.sol";

enum TOKEN_CHOICE { BONK, USDT, OTHERS }

struct Asset {
    IERC20 bonkToken;
    IERC20 usdtToken;
}

struct Supply {
    uint256 bonkSupply;
    uint256 usdtSupply;
}

struct Reserve {
    uint256 bonkReserve;
    uint256 usdtReserve;
}

contract ArcadeVault is Initializable, UUPSUpgradeable, Ownable{
    
    using SafeERC20 for IERC20;

    Asset public assets;
    Supply public supplies;
    Reserve public reserves;
    ArcadeManager public manager;
    address public exchangeCenter;

    function initialize(address _manager, address _exc, address _bonkToken, address _usdtToken, uint256 _bs, uint256 _usdts, uint256 _brsv, uint256 _usdtrsv) public initializer {
        assets.bonkToken = IERC20(_bonkToken);
        assets.usdtToken = IERC20(_usdtToken);
        supplies.bonkSupply = _bs;
        supplies.usdtSupply = _usdts;
        reserves.bonkReserve = _brsv;
        reserves.usdtReserve = _usdtrsv;
        manager = ArcadeManager(_manager);
        exchangeCenter = _exc;
   }

   function _authorizeUpgrade(address) internal override onlyOwner {}

    modifier onlyManager {
        bool check = manager.checkManager(msg.sender);
        bool checkExchange;
        if (check || msg.sender == exchangeCenter) {
            _;
        } else {
            revert("You are not authorized");
        }
    }

   function validateSupplies(TOKEN_CHOICE _t, uint256 _a) internal view returns (bool) {
       if (_t == TOKEN_CHOICE.BONK) {
           if (_a > supplies.bonkSupply) {
               return false;
           }
           return true;
       } else if (_t == TOKEN_CHOICE.USDT) {
           if (_a > supplies.usdtSupply) {
               return false;
           }
           return true;
       }
       return false;
   }

   function updateReserves(TOKEN_CHOICE _t, uint256 _amount) external onlyManager returns (bool _r) {
       if (_t == TOKEN_CHOICE.BONK) {
           reserves.bonkReserve += _amount;
           return true;
        } else if (_t == TOKEN_CHOICE.USDT) {
            reserves.usdtReserve += _amount;
            return true;
        }
        return false;
   }

   function getTokens() external view returns (address, address) {
       address bonk = address(assets.bonkToken);
       address usdt = address(assets.usdtToken);
       return (bonk,usdt);
   }

   function getSupplies() external view returns (uint256, uint256) {
       uint256 bonkTotal = supplies.bonkSupply;
       uint256 usdtTotal = supplies.usdtSupply;
       return (bonkTotal, usdtTotal);
   }

   function getReserves() external view returns (uint256, uint256) {
       uint256 bonkReserve = reserves.bonkReserve;
       uint256 usdtReserve = reserves.usdtReserve;
       return (bonkReserve, usdtReserve);
    }

    function checkSupplies(TOKEN_CHOICE _t, uint256 _a) external view returns (bool _r) {
        if (_t == TOKEN_CHOICE.BONK && _a <= supplies.bonkSupply) {
            return true;
        } else if (_t == TOKEN_CHOICE.USDT && _a <= supplies.usdtSupply) {
            return true;
        }
        return false;
    }

    function setExchange(address _e) external onlyOwner {
        exchangeCenter = _e;
    }

    function setToken(TOKEN_CHOICE _t, address _a) external onlyOwner {
        if (_t == TOKEN_CHOICE.BONK) {
            assets.bonkToken = IERC20(_a);
        } else if (_t == TOKEN_CHOICE.USDT) {
            assets.usdtToken = IERC20(_a);
        } else {
        revert("Token not available");
        }
    }

    function deposit(TOKEN_CHOICE _t, uint256 _a) external onlyOwner {
        if (_t == TOKEN_CHOICE.BONK) {
            assets.bonkToken.safeTransferFrom(msg.sender, address(this), _a);
            supplies.bonkSupply += _a;
        } else if (_t == TOKEN_CHOICE.USDT) {
            assets.usdtToken.safeTransferFrom(msg.sender, address(this), _a);
            supplies.usdtSupply += _a;
        }
    }

    function exchangeTransfer(TOKEN_CHOICE _t, address _u, uint256 _a) external onlyManager {
       bool check = validateSupplies(_t, _a);
       if (!check) {
           revert("Not Available!");
       } 
       if (_t == TOKEN_CHOICE.BONK) {
           assets.bonkToken.safeTransfer(_u,_a);
           supplies.bonkSupply -= _a;
       } else if (_t == TOKEN_CHOICE.USDT) {
           assets.usdtToken.safeTransfer(_u,_a);
           supplies.usdtSupply -= _a;
       } else {
        revert("Cannot withdraw");       
       }
   }

   function setManager(address _m) external onlyOwner {
       manager = ArcadeManager(_m);
   }
}
