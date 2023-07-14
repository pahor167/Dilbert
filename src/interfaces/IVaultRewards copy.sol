// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IVaultRewards {
    function balanceOf(address account) external view returns (uint256);
    function stakeFromVault(uint256 amount, address account) external;
    function withdrawToVault(uint256 amount, address account) external;
}
