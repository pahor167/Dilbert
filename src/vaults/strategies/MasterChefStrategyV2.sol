// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/utils/Address.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/access/Ownable.sol";

import "../../interfaces/IMasterChef.sol";
import "../../interfaces/IRouter.sol";
import "../../interfaces/IProtocolAddresses.sol";
import "../../interfaces/IPair.sol";
import "../../interfaces/IStrategyVariables.sol";


/**
 * @title Cycle Protocol MasterChef Strategy
 * @dev Autocompound rewards from MasterChef reward contracts
 */
contract MasterChefStrategyV2 is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    address public constant WAVAX = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    address public Router;
    address public MasterChef;
    address public RewardToken;
    address public Vault;
    address public LPtoken;
    address public Token0;
    address public Token1;
    uint8 public poolID;

    address public ProtocolAddresses;
    address public StrategyVariables;

    address[] public RewardTokenToWAVAXpath;
    address[] public RewardTokenToToken0path;
    address[] public RewardTokenToToken1path;

    uint256 public constant BASIS_POINT_DIVISOR = 10000;

    event ProtocolAddressesUpdated(address ProtocolAddresses);
    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);
    event HarvestRun(address indexed caller, uint256 amount);
    event HarvestFeeProcessed(uint256 amount);
    event CallFeeProcessed(uint256 amount);

    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    constructor(
        address _LPtoken,
        uint8 _poolID,
        address _Vault,
        address _StrategyVariables,
        address _MasterChef,
        address _RewardToken,
        address _Router
    ) {
        LPtoken = _LPtoken;
        Token0 = IPair(LPtoken).token0();
        Token1 = IPair(LPtoken).token1();
        poolID = _poolID;
        Vault = _Vault;
        StrategyVariables = _StrategyVariables;
        MasterChef = _MasterChef;
        RewardToken = _RewardToken;
        Router = _Router;

        RewardTokenToWAVAXpath = [RewardToken, WAVAX];

        if (Token0 == WAVAX) {
            RewardTokenToToken0path = [RewardToken, WAVAX];
        } else if (Token0 != RewardToken) {
            RewardTokenToToken0path = [RewardToken, WAVAX, Token0];
        }

        if (Token1 == WAVAX) {
            RewardTokenToToken1path = [RewardToken, WAVAX];
        } else if (Token1 != RewardToken) {
            RewardTokenToToken1path = [RewardToken, WAVAX, Token1];
        }

        IERC20(RewardToken).safeApprove(Router, 0);
        IERC20(RewardToken).safeApprove(Router, MAX_INT);
        IERC20(Token0).safeApprove(Router, 0);
        IERC20(Token0).safeApprove(Router, MAX_INT);
        IERC20(Token1).safeApprove(Router, 0);
        IERC20(Token1).safeApprove(Router, MAX_INT);
    }

    receive() external payable {}

    modifier onlyVault() {
        require(msg.sender == Vault, "MasterChefStrategyV2: Caller is not the Vault");
        _;
    }

    function setProtocolAddresses(address _ProtocolAddresses) external onlyOwner {
        ProtocolAddresses = _ProtocolAddresses;
        emit ProtocolAddressesUpdated(ProtocolAddresses);
    }

    function balanceLP() public view returns (uint256) {
        return IERC20(LPtoken).balanceOf(address(this));
    }

    function masterChefBalanceLP() public view returns (uint256 amount) {
        (amount,) = IMasterChef(MasterChef).userInfo(poolID, address(this));
    }

    function balanceLPinStrategy() external view returns (uint256) {
        return balanceLP() + (masterChefBalanceLP());
    }

    function balanceRewardToken() public view returns (uint256) {
        return IERC20(RewardToken).balanceOf(address(this));
    }

    // Customize per deploy
    // Withdraws from MasterChef claim pending rewards, so better to show pending + balance
    function getRewardsEarned() external view returns (uint256) {
        uint256 pendingRewards = IMasterChef(MasterChef).pending__FILL__(poolID, address(this));
        return pendingRewards + (balanceRewardToken());
    }

    /**
     * @dev Deposits will be paused when strategy has been decommissioned
     */
    function deposit() public whenNotPaused {
        uint256 balance = balanceLP();
        require(balance > 0, "MasterChefStrategyV2: Deposit called with 0 balance");
        IERC20(LPtoken).safeIncreaseAllowance(MasterChef, balance);
        IMasterChef(MasterChef).deposit(poolID, balance);
        emit Deposit(balance);
    }

    /**
     * @dev Uses available balance in strategy, withdrawing from Masterchef to make up difference
     */
    function withdraw(uint256 amount) external onlyVault {
        uint256 balance = balanceLP();

        if (balance < amount) {
            IMasterChef(MasterChef).withdraw(poolID, amount - (balance));
            balance = balanceLP();
        }

        if (balance > amount) {
            balance = amount;
        }

        IERC20(LPtoken).safeTransfer(Vault, balance);
        emit Withdraw(amount);
    }

    function harvest() external whenNotPaused nonReentrant {
        require(!Address.isContract(msg.sender), "MasterChefStrategyV2: Caller is not an EOA");
        IMasterChef(MasterChef).deposit(poolID, 0);
        uint256 harvestAmount = balanceRewardToken();
        _processFees(harvestAmount);
        _addLiquidity();
        deposit();
        emit HarvestRun(msg.sender, harvestAmount);
    }

    /**
     * @dev Harvest fee and Call fee processed together
     */
    function _processFees(uint256 harvestAmount) internal {
        uint256 harvestFeeBasisPoints = IStrategyVariables(StrategyVariables).harvestFeeBasisPoints();
        uint256 callFeeBasisPoints = IStrategyVariables(StrategyVariables).callFeeBasisPoints();
        uint256 totalFeeBasisPoints = harvestFeeBasisPoints + (callFeeBasisPoints);

        uint256 harvestAmountFee = harvestAmount * (totalFeeBasisPoints) / (BASIS_POINT_DIVISOR);

        IRouter(Router).swapExactTokensForTokens(harvestAmountFee, 0, RewardTokenToWAVAXpath, address(this), block.timestamp + 120);

        uint256 balanceWAVAX = IERC20(WAVAX).balanceOf(address(this));

        uint256 WAVAXforProcessor = balanceWAVAX * (harvestFeeBasisPoints) / (totalFeeBasisPoints);
        uint256 WAVAXforCaller = balanceWAVAX - (WAVAXforProcessor);

        address HarvestProcessor = IProtocolAddresses(ProtocolAddresses).HarvestProcessor();
        IERC20(WAVAX).safeTransfer(HarvestProcessor, WAVAXforProcessor);
        emit HarvestFeeProcessed(WAVAXforProcessor);

        IERC20(WAVAX).safeTransfer(msg.sender, WAVAXforCaller);
        emit CallFeeProcessed(WAVAXforCaller);
    }

    function _addLiquidity() internal {
        uint256 halfRewardToken = balanceRewardToken() / (2);

        if (Token0 != RewardToken) {
            IRouter(Router).swapExactTokensForTokens(halfRewardToken, 0, RewardTokenToToken0path, address(this), block.timestamp + 120);
        }

        if (Token1 != RewardToken) {
            IRouter(Router).swapExactTokensForTokens(halfRewardToken, 0, RewardTokenToToken1path, address(this), block.timestamp + 120);
        }

        uint256 balanceToken0 = IERC20(Token0).balanceOf(address(this));
        uint256 balanceToken1 = IERC20(Token1).balanceOf(address(this));

        IRouter(Router).addLiquidity(Token0, Token1, balanceToken0, balanceToken1, 0, 0, address(this), block.timestamp + 120);
    }

    /**
     * @dev This will be called once when the Vault/Strategy is being decommissioned
     * Remaining rewards will be sent to the HarvestProcessor
     * All LP tokens will be sent back to the vault and can be withdrawn from there
     * Deposits will be paused
     *
     * WARNING: The strategy will not be able to restart
     */
    function decommissionStrategy() external onlyVault {
        IMasterChef(MasterChef).deposit(poolID, 0);
        uint256 receivedRewardToken = balanceRewardToken();
        if (receivedRewardToken > 0) {
            _processFees(receivedRewardToken);
        }

        IMasterChef(MasterChef).emergencyWithdraw(poolID);

        uint256 balance = balanceLP();
        IERC20(LPtoken).safeTransfer(Vault, balance);

        _pause();
    }
}
