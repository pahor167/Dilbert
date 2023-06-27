// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin-contracts/utils/Context.sol";
import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/utils/Address.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/utils/math/Math.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/security/Pausable.sol";
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
