// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Address provider 0xeb7A892BB04A8f836bDEeBbf60897A7Af1Bf5d7F

contract Strategy is ERC4626 {

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    IPool public immutable aave;
    IERC20 public bondasset;

    
  
    constructor(ERC20 _asset, string memory _name, string memory _symbol,address _addressProvider,address _bondasset)ERC4626(_asset, _name, _symbol){
        ADDRESSES_PROVIDER = IPoolAddressesProvider(_addressProvider);
        aave = IPool(ADDRESSES_PROVIDER.getPool());
        bondasset=IERC20(_bondasset);
    }

     function totalAssets() public view override returns(uint256){
        return bondasset.balanceOf(address(this));
    }

    function sendDaiToAave(uint256 amount) internal {
        aave.supply(address(asset),amount,address(this),0);
    }

    function _withdrawDaiFromAave(uint256 _amount) internal {
        aave.withdraw(address(asset), _amount, msg.sender);
    }

    function approveDai(uint256 amount) internal{
        asset.approve(address(aave),amount);
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256 shares){
         
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

    
        asset.transferFrom(msg.sender, address(this), assets);
        approveDai(assets);
        sendDaiToAave(assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);
        _withdrawDaiFromAave(assets);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }
}