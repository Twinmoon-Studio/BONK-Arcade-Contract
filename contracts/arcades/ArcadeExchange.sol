// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/arcades/ArcadeManager.sol";
import "contracts/arcades/ArcadeVault.sol";


contract ArcadeExchange is Initializable, UUPSUpgradeable, Ownable {

    enum EXCHANGE_LIST { BONK_TO_USDT, USDT_TO_BONK, BONK_TO_BAM, BAM_TO_BONK }
    using SafeERC20 for IERC20;
    ArcadeVault public vault;
    ArcadeManager public manager;
    uint16 public bonkPrice;
    uint256 public interestRate;

    function initialize(address _m, address _v, uint16 _bp, uint256 _ir) public initializer {
        manager = ArcadeManager(_m);
        vault = ArcadeVault(_v);
        bonkPrice = _bp;
        interestRate = _ir;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    modifier onlyManager {
        bool check = manager.checkManager(msg.sender);
        if (check) {
            _;
        }
        revert("You are not authorized");
    }

    function validateToken(address _m, address _check) internal pure returns (bool) {
        if (_m == _check) {
            return true;
        }
        return false;
    }

    function getTokens() internal view returns (IERC20 _b ,IERC20 _u) {
        address bonkTokenAddr;
        address usdtTokenAddr;
        (bonkTokenAddr, usdtTokenAddr) = vault.getTokens();
        
        IERC20 bonkToken = IERC20(bonkTokenAddr);
        IERC20 usdtToken = IERC20(usdtTokenAddr);

        return (bonkToken, usdtToken);
    }

    function calculateFees(uint256 _amount) internal view returns (uint256, uint256) {
        uint256 serviceCharge = _amount / interestRate;
        uint256 totalAmount = _amount - serviceCharge;
        return (totalAmount, serviceCharge);
    }

    function calculateBonkToUSDT(uint256 _amount) internal view returns (uint256) {
        uint256 totalAmount = _amount * bonkPrice;
        return totalAmount;
    }

    function calculateUSDTToBonk(uint256 _amount) internal view returns (uint256) {
        uint256 totalAmount = _amount / bonkPrice;
        return totalAmount;
    }

    function updateBonkMarketPrice(uint16 _amount) external onlyManager {
        bonkPrice = _amount;
    }


    function setVault(address _v) onlyOwner external {
        vault = ArcadeVault(_v);
    }

    function setManager(address _v) onlyOwner external {
        manager = ArcadeManager(_v);
    }

    function getManager() external view returns (address payable) {
        address payable mng = manager.manager();
        return mng;
    }

    function exchangeUSDTToBonk(EXCHANGE_LIST _el, uint256 _amount) external {
        bool checkSupplies = vault.checkSupplies(TOKEN_CHOICE.BONK, _amount);
        if (_el == EXCHANGE_LIST.USDT_TO_BONK && checkSupplies) {
            uint256 totalAmount;
            uint256 serviceCharge;
            (totalAmount, serviceCharge) = calculateFees(_amount);
            uint256 estimate = calculateUSDTToBonk(totalAmount);
            IERC20 bonkToken;
            IERC20 usdtToken;
            (bonkToken, usdtToken) = getTokens();
            usdtToken.safeTransferFrom(msg.sender,address(vault),_amount);
            vault.exchangeTransfer(TOKEN_CHOICE.BONK , msg.sender, estimate);
            vault.updateReserves(TOKEN_CHOICE.USDT, serviceCharge);
        } else {
            revert("Invalid choice");
        }
    }

    function exchangeBonkToUSDT(EXCHANGE_LIST _el, uint256 _amount) external {
        bool checkSupplies = vault.checkSupplies(TOKEN_CHOICE.USDT, _amount);
        if (_el == EXCHANGE_LIST.BONK_TO_USDT && checkSupplies) {
            uint256 totalAmount;
            uint256 serviceCharge;
            (totalAmount, serviceCharge) = calculateFees(_amount);
            uint256 estimate = calculateBonkToUSDT(totalAmount);
            IERC20 bonkToken;
            IERC20 usdtToken;
            (bonkToken, usdtToken) = getTokens();
            bonkToken.safeTransferFrom(msg.sender,address(vault),_amount);
            vault.exchangeTransfer(TOKEN_CHOICE.USDT,msg.sender, estimate);
            vault.updateReserves(TOKEN_CHOICE.BONK, serviceCharge);
        } else {
            revert("Invalid choice");
        }
    }
}