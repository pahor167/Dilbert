// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "openzeppelin-contracts/access/Ownable.sol";

import "./interfaces/ICycle.sol";

contract CycleManager is Ownable {
    address public CYCLE = address(0x81440C939f2C1E34fc7048E518a637205A632a74);

    function setDistributor(address _Distributor) external onlyOwner {
        ICycle(CYCLE).setDistributor(_Distributor);
    }

    function setScalingFactor(uint256 _scalingFactor) external onlyOwner {
        require(_scalingFactor <= 100, "CycleManager: Input Out of Bounds");
        ICycle(CYCLE).setScalingFactor(_scalingFactor);
    }
}
