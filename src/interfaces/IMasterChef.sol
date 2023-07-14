// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function emergencyWithdraw(uint256 _pid) external;
    function pendingTokens(uint256 _pid, address _user) external view returns (uint256, address, string memory, uint256);
    // customize this function based on the protocol MC function
    function pending__FILL__(uint256 _pid, address _user) external view returns (uint256);
}
