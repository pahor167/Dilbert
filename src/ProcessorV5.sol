// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";

import "./interfaces/IWAVAX.sol";
import "./interfaces/IStakingRewards.sol";
import "./interfaces/ICycle.sol";

/**
 * @title Processor V5
 * @dev Transfer to AVAX rewards, team and control daily emission
 */
contract ProcessorV5 is Ownable {
    using SafeERC20 for IERC20;

    address public constant CYCLE = address(0x81440C939f2C1E34fc7048E518a637205A632a74);
    address public constant WAVAX = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    uint256 public constant BP_DIV = 10000;

    address public AVAXRewards;
    address public Proxy;
    address public Team;
    uint256 public teamBP;
    uint256 public emission;

    event RewardsProcessed(uint256 amountCYCLE);
    event AVAXRewardsUpdated(address AVAXRewards);
    event ProxyUpdated(address Proxy);
    event TeamUpdated(address Team);
    event TeamBPUpdated(uint256 teamBP);
    event EmissionUpdated(uint256 newEmission);

    constructor(
        address _AVAXRewards,
        address _Proxy,
        address _Team,
        uint256 _teamBP,
        uint256 _emission
    ) {
        AVAXRewards = _AVAXRewards;
        Proxy = _Proxy;
        Team = _Team;
        teamBP = _teamBP;
        emission = _emission;
    }

    receive() external payable {}

    modifier onlyProxy() {
        require(msg.sender == Proxy, "ProcessorV5: Caller must be the Proxy");
        _;
    }

    /**
     * @dev Owner Controls
     */
    function setEmission(uint256 newEmission) external onlyOwner {
        emission = newEmission;
        emit EmissionUpdated(newEmission);
    }

    function setAVAXRewards(address _AVAXRewards) external onlyOwner {
        AVAXRewards = _AVAXRewards;
        emit AVAXRewardsUpdated(AVAXRewards);
    }

    function setProxy(address _Proxy) external onlyOwner {
        Proxy = _Proxy;
        emit ProxyUpdated(Proxy);
    }

    function setTeam(address _Team) external onlyOwner {
        Team = _Team;
        emit TeamUpdated(Team);
    }

    function setTeamBP(uint256 _teamBP) external onlyOwner {
        teamBP = _teamBP;
        emit TeamBPUpdated(teamBP);
    }

    // In case rewards need to be cleared for update
    function clearRewards() external onlyOwner {
        IERC20(CYCLE).safeTransfer(msg.sender, balanceCYCLE());
    }

    function balanceWAVAX() public view returns (uint256) {
        return IERC20(WAVAX).balanceOf(address(this));
    }

    function balanceCYCLE() public view returns (uint256) {
        return IERC20(CYCLE).balanceOf(address(this));
    }

    function process() external onlyProxy {
        uint256 balanceAVAX = address(this).balance;
        if (balanceAVAX > 0) {
            IWAVAX(WAVAX).deposit{value: balanceAVAX}();
        }

        uint256 balWAVAX = balanceWAVAX();
        uint256 teamFee = balWAVAX * (teamBP) / (BP_DIV);
        IERC20(WAVAX).safeTransfer(Team, teamFee);
        uint256 rewardAmount = balanceWAVAX();
        IERC20(WAVAX).safeTransfer(AVAXRewards, rewardAmount);
        IStakingRewards(AVAXRewards).notifyRewardAmount(rewardAmount);

        uint256 balCYCLE = balanceCYCLE();
        uint256 amountToSend = balCYCLE < emission ? balCYCLE : emission;
        ICycle(CYCLE).authorize(amountToSend);
        ICycle(CYCLE).cycle(amountToSend);

        emit RewardsProcessed(amountToSend);
    }
}
