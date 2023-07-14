// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ICycleVault {
    function balanceLPinSystem() external view returns (uint256);
    function getAVAXquoteForLPamount(uint256 amountLP) external view returns (uint256);
}
