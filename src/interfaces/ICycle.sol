// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ICycle {
    function authorize(uint256 amount) external;
    function cycle(uint256 amountIn) external;
}
