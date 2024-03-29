// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./libs/AMMLibrary.sol";

/**
 * @title Price Helper
 * @dev Simple spot price provider from AVAX to DAI
 */
contract PriceHelper {
    address public WAVAX = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    address public DAI = address(0xbA7dEebBFC5fA1100Fb055a87773e1E99Cd3507a);
    address public Factory = address(0xefa94DE7a4656D787667C749f7E1223D71E9FD88);
    
    function getAVAXtoUSD(uint256 amountWAVAX) external view returns (uint256) {
        (uint256 reservesWAVAX, uint256 reservesDAI) = AMMLibrary.getReserves(Factory, WAVAX, DAI);

        uint256 currentAVAXprice = AMMLibrary.quote(1e18, reservesWAVAX, reservesDAI);

        return amountWAVAX * currentAVAXprice / 1e18;
    }
}
