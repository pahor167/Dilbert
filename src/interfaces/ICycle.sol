// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ICycle {
    function authorize(uint256 amount) external;
    function cycle(uint256 amountIn) external;
    function setDistributor(address _Distributor) external;
    function setScalingFactor(uint256 _scalingFactor) external;
}
