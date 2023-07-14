import "./libs/PangolinLibrary.sol";
import "./libs/AMMLibrary.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IProtocolAddresses.sol";
import "./interfaces/IProcessor.sol";
import "./interfaces/IStrategyVariables.sol";
import "./interfaces/IWAVAX.sol";
import "./interfaces/IHarvestProcessor.sol";
import "./interfaces/IStakingRewards.sol";
import "./interfaces/IVaultRewards.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IJoeBar.sol";
import "./interfaces/ICycleVault.sol";
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @title Price Helper
 * @dev Simple spot price provider from AVAX to USDT.e
 */
contract PriceHelperV2 {
    using SafeMath for uint256;

    address public WAVAX = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    address public USDTe = address(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    address public Factory = address(0xefa94DE7a4656D787667C749f7E1223D71E9FD88);
    
    function getAVAXtoUSD(uint256 amountWAVAX) external view returns (uint256) {
        (uint256 reservesWAVAX, uint256 reservesUSDTe) = AMMLibrary.getReserves(Factory, WAVAX, USDTe);

        uint256 currentAVAXprice = AMMLibrary.quote(1e18, reservesWAVAX, reservesUSDTe);

        return amountWAVAX.mul(currentAVAXprice).div(1e18);
    }
}
