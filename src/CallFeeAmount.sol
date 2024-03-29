// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./libs/AMMLibrary.sol";
import "./interfaces/IStrategyVariables.sol";
import "./interfaces/IWAVAX.sol";
import "./interfaces/IStrategy.sol";

/**
 * @title Fee Helper
 * @dev Calculates caller fee output amount in WAVAX using current reward harvest amount
 * @dev Deploy per exchange / Reward Token, set init code hash and Factory as required
 */
contract CallFeeAmount {

    address public WAVAX = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    address public RewardToken = address(0x60781C2586D68229fde47564546784ab3fACA982); // PNG
    address public Factory = address(0xefa94DE7a4656D787667C749f7E1223D71E9FD88); // Pangolin

    uint256 public BP_DIVISOR = 10000;

    function getCallFeeAmount(address Strategy, address StrategyVariables) external view returns (uint256) {
        uint256 rewardsEarned = IStrategy(Strategy).getRewardsEarned();

        (uint256 reservesWAVAX, uint256 reservesRewardToken) = AMMLibrary.getReserves(Factory, WAVAX, RewardToken);

        uint256 amountWAVAX = AMMLibrary.getAmountOut(rewardsEarned, reservesRewardToken, reservesWAVAX);

        uint256 callFeeBP = IStrategyVariables(StrategyVariables).callFeeBasisPoints();

        return amountWAVAX * (callFeeBP) / (BP_DIVISOR);
    }
}
