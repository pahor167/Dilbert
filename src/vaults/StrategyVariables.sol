// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract StrategyVariables is Ownable {
    uint256 public harvestFeeBasisPoints;
    uint256 public callFeeBasisPoints;

    event HarvestFeeBasisPointsUpdated(uint256 harvestFeeBasisPoints);
    event CallFeeBasisPointsUpdated(uint256 callFeeBasisPoints);

    function setHarvestFeeBasisPoints(uint256 _points) external onlyOwner {
        harvestFeeBasisPoints = _points;
        emit HarvestFeeBasisPointsUpdated(harvestFeeBasisPoints);
    }

    function setCallFeeBasisPoints(uint256 _points) external onlyOwner {
        callFeeBasisPoints = _points;
        emit CallFeeBasisPointsUpdated(callFeeBasisPoints);
    }
}
