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

import "../libs/SafeMath.sol";
import "../libs/AMMLibrary.sol";
import "../interfaces/IMasterChef.sol";
import "../interfaces/IRouter.sol";
import "../interfaces/IProtocolAddresses.sol";
import "../interfaces/IPair.sol";
import "../interfaces/IStrategyVariables.sol";
import "../interfaces/IWAVAX.sol";
import "../interfaces/IHarvestProcessor.sol";
import "../interfaces/IStakingRewards.sol";
import "../interfaces/IVaultRewards.sol";
import "../interfaces/IStrategy.sol";


pragma solidity ^0.8.13;

/**
 * @title Cycle Vault V3
 * @dev Access point for deposit/withdraw from strategies and rewards 
 */
contract CycleVaultV3 is ERC20, ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    address public constant WAVAX = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    address public Factory;
    address public Router;
    address public VaultRewards;
    address public Strategy;
    address public LPtoken;
    address public Token0;
    address public Token1;

    address[] public WAVAXtoToken0path;
    address[] public WAVAXtoToken1path;
    address[] public Token0toWAVAXpath;
    address[] public Token1toWAVAXpath;

    bool public strategySet;
    bool public rewardsSet;

    event AVAXdeposited(uint256 amountAVAX);
    event LPdeposited(uint256 amountLP);
    event SharesStaked(uint256 shares, address indexed account);
    event LPdepositedInStrategy(uint256 amountLP);
    event AVAXwithdrawn(uint256 amountAVAX);
    event LPwithdrawn(uint256 amountLP);
    event SharesWithdrawn(uint256 shares, address indexed account);
    event LPwithdrawnFromStrategy(uint256 amountLP);
    event VaultDecommissioned(uint256 decommissionTime);

    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    constructor(
        string memory _name, 
        string memory _symbol,
        address _LPtoken,
        address _Factory,
        address _Router
    ) ERC20(string(_name), string(_symbol)) {
        LPtoken = _LPtoken;
        Token0 = IPair(LPtoken).token0();
        Token1 = IPair(LPtoken).token1();
        Factory = _Factory;
        Router = _Router;

        WAVAXtoToken0path = [WAVAX, Token0];
        WAVAXtoToken1path = [WAVAX, Token1];
        Token0toWAVAXpath = [Token0, WAVAX];
        Token1toWAVAXpath = [Token1, WAVAX];

        IERC20(WAVAX).safeApprove(Router, 0);
        IERC20(WAVAX).safeApprove(Router, MAX_INT);
        IERC20(LPtoken).safeApprove(Router, 0);
        IERC20(LPtoken).safeApprove(Router, MAX_INT);
        IERC20(Token0).safeApprove(Router, 0);
        IERC20(Token0).safeApprove(Router, MAX_INT);
        IERC20(Token1).safeApprove(Router, 0);
        IERC20(Token1).safeApprove(Router, MAX_INT);
    }

    receive() external payable {}

    /**
     * @dev Strategies and reward contracts will be set once and not updated per vault
     */
    function setStrategy(address _Strategy) external onlyOwner {
        require(!strategySet, "CycleVaultV3: Strategy address has already been set");
        Strategy = _Strategy;
        strategySet = true;
    }

    function setVaultRewards(address _VaultRewards) external onlyOwner {
        require(!rewardsSet, "CycleVaultV3: Rewards address has already been set");
        VaultRewards = _VaultRewards;
        rewardsSet = true;
    }

    /**
     * @dev Balance helpers
     */
    function balanceLPinVault() public view returns (uint256) {
        return IERC20(LPtoken).balanceOf(address(this));
    }

    function balanceLPinStrategy() public view returns (uint256) {
        return IStrategy(Strategy).balanceLPinStrategy();
    }

    function balanceLPinSystem() public view returns (uint256) {
        return balanceLPinVault() + balanceLPinStrategy();
    }

    // Need to view shares owned through reward contract as an account will never actually hold vault shares
    function accountShareBalance(address account) public view returns (uint256) {
        return IVaultRewards(VaultRewards).balanceOf(account);
    }

    function getAccountLP(address account) public view returns (uint256) {
        return totalSupply() == 0 ? 0 : balanceLPinSystem() * accountShareBalance(account) / totalSupply();
    }

    function getAVAXamountForAccountLP(address account) external view returns (uint256) {
        return getAVAXamountForLPamount(getAccountLP(account));
    }

    function getLPamountForShares(uint256 shares) public view returns (uint256) {
        return totalSupply() == 0 ? 1e18 : balanceLPinSystem() * shares / totalSupply();
    }

    // Using {getAmountOut} to provide AVAX value closer to what a withdraw would receive
    function getAVAXamountForLPamount(uint256 amountLP) public view returns (uint256) {
        if (amountLP == 0) return 0;
        (uint256 reservesToken0, uint256 reservesToken1) = AMMLibrary.getReserves(Factory, Token0, Token1);

        uint256 totalSupplyLP = IERC20(LPtoken).totalSupply();

        uint256 amountToken0 = reservesToken0 * amountLP / totalSupplyLP;
        uint256 amountToken1 = reservesToken1 * amountLP / totalSupplyLP;

        if (Token0 == WAVAX) {
            uint256 Token1toWAVAX = AMMLibrary.getAmountOut(amountToken1, reservesToken1, reservesToken0);
            return amountToken0 + Token1toWAVAX;
        } else if (Token1 == WAVAX) {
            uint256 Token0toWAVAX = AMMLibrary.getAmountOut(amountToken0, reservesToken0, reservesToken1);
            return amountToken1 + Token0toWAVAX;
        } else {
            (uint256 reservesWAVAX0, uint256 reserves0) = AMMLibrary.getReserves(Factory, WAVAX, Token0);
            (uint256 reservesWAVAX1, uint256 reserves1) = AMMLibrary.getReserves(Factory, WAVAX, Token1);
            uint256 Token0toWAVAX = AMMLibrary.getAmountOut(amountToken0, reserves0, reservesWAVAX0);
            uint256 Token1toWAVAX = AMMLibrary.getAmountOut(amountToken1, reserves1, reservesWAVAX1);
            return Token0toWAVAX + Token1toWAVAX;
        }
    }

    // Using {quote} to provide more exact proportion of AVAX held
    // Will be mostly called when calculating TVL for vault
    function getAVAXquoteForLPamount(uint256 amountLP) public view returns (uint256) {
        if (amountLP == 0) return 0;
        (uint256 reservesToken0, uint256 reservesToken1) = AMMLibrary.getReserves(Factory, Token0, Token1);

        uint256 totalSupplyLP = IERC20(LPtoken).totalSupply();

        uint256 amountToken0 = reservesToken0 * amountLP / totalSupplyLP;
        uint256 amountToken1 = reservesToken1 * amountLP / totalSupplyLP;

        if (Token0 == WAVAX) {
            uint256 Token1toWAVAX = AMMLibrary.quote(amountToken1, reservesToken1, reservesToken0);
            return amountToken0 + Token1toWAVAX;
        } else if (Token1 == WAVAX) {
            uint256 Token0toWAVAX = AMMLibrary.quote(amountToken0, reservesToken0, reservesToken1);
            return amountToken1 + Token0toWAVAX;
        } else {
            (uint256 reservesWAVAX0, uint256 reserves0) = AMMLibrary.getReserves(Factory, WAVAX, Token0);
            (uint256 reservesWAVAX1, uint256 reserves1) = AMMLibrary.getReserves(Factory, WAVAX, Token1);
            uint256 Token0toWAVAX = AMMLibrary.quote(amountToken0, reserves0, reservesWAVAX0);
            uint256 Token1toWAVAX = AMMLibrary.quote(amountToken1, reserves1, reservesWAVAX1);
            return Token0toWAVAX + Token1toWAVAX;
        }
    }

    /**
     * @dev Deposit logic
     */
    function depositAVAX() external payable nonReentrant whenNotPaused {
        uint256 amountAVAX = msg.value;
        require(amountAVAX > 0, "CycleVaultV3: 0 AVAX deposit");
        emit AVAXdeposited(amountAVAX);

        IWAVAX(WAVAX).deposit{value: amountAVAX}();

        uint256 halfAmountWAVAX = amountAVAX / 2;

        if (Token0 == WAVAX) {
            IRouter(Router).swapExactTokensForTokens(halfAmountWAVAX, 0, WAVAXtoToken1path, address(this), block.timestamp + 120);    
        } else if (Token1 == WAVAX) {
            IRouter(Router).swapExactTokensForTokens(halfAmountWAVAX, 0, WAVAXtoToken0path, address(this), block.timestamp + 120);
        } else {
            IRouter(Router).swapExactTokensForTokens(halfAmountWAVAX, 0, WAVAXtoToken0path, address(this), block.timestamp + 120);
            IRouter(Router).swapExactTokensForTokens(halfAmountWAVAX, 0, WAVAXtoToken1path, address(this), block.timestamp + 120);
        }

        uint256 balanceToken0 = IERC20(Token0).balanceOf(address(this));
        uint256 balanceToken1 = IERC20(Token1).balanceOf(address(this));

        uint256 previousBalanceLPinSystem = balanceLPinSystem();

        (,, uint256 amountLP) = IRouter(Router).addLiquidity(Token0, Token1, balanceToken0, balanceToken1, 0, 0, address(this), block.timestamp + 120);

        _deposit(amountLP, previousBalanceLPinSystem);
    }

    function depositLP(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "CycleVaultV3: 0 LP deposit");
        emit LPdeposited(amount);

        uint256 previousBalanceLPinSystem = balanceLPinSystem();

        IERC20(LPtoken).safeTransferFrom(msg.sender, address(this), amount);

        _deposit(amount, previousBalanceLPinSystem);
    }

    function _deposit(uint256 amount, uint256 systemBalance) internal {
        uint256 shares = 0;
        
        if (totalSupply() == 0) {
            shares = amount;
        } else {
            shares = (amount * totalSupply()) / systemBalance;
        }

        // mint shares to the vault, then deposit on behalf of msg.sender
        _mint(address(this), shares);
        _approve(address(this), VaultRewards, shares);
        IVaultRewards(VaultRewards).stakeFromVault(shares, msg.sender);
        emit SharesStaked(shares, msg.sender);

        IERC20(LPtoken).safeTransfer(Strategy, amount);
        IStrategy(Strategy).deposit();
        emit LPdepositedInStrategy(amount);
    }

    /**
     * @dev Withdraw logic
     */
    function withdrawAVAX(uint256 sharesToWithdraw) external nonReentrant {
        uint256 sharesOwned = accountShareBalance(msg.sender);
        require(sharesToWithdraw <= sharesOwned, "CycleVaultV3: Insufficient share balance for withdraw");

        uint256 amountLPforWithdraw = _withdraw(sharesToWithdraw);

        IRouter(Router).removeLiquidity(Token0, Token1, amountLPforWithdraw, 0, 0, address(this), block.timestamp + 120);

        uint256 balanceToken0 = IERC20(Token0).balanceOf(address(this));
        uint256 balanceToken1 = IERC20(Token1).balanceOf(address(this));

        if (Token0 == WAVAX) {
            IRouter(Router).swapExactTokensForTokens(balanceToken1, 0, Token1toWAVAXpath, address(this), block.timestamp + 120);
        } else if (Token1 == WAVAX) {
            IRouter(Router).swapExactTokensForTokens(balanceToken0, 0, Token0toWAVAXpath, address(this), block.timestamp + 120);
        } else {
            IRouter(Router).swapExactTokensForTokens(balanceToken0, 0, Token0toWAVAXpath, address(this), block.timestamp + 120);
            IRouter(Router).swapExactTokensForTokens(balanceToken1, 0, Token1toWAVAXpath, address(this), block.timestamp + 120);
        }

        uint256 balanceWAVAX = IERC20(WAVAX).balanceOf(address(this));

        IWAVAX(WAVAX).withdraw(balanceWAVAX);

        (bool success, ) = msg.sender.call{value: balanceWAVAX}("");
        require(success, "CycleVaultV3: Unable to transfer AVAX");

        emit AVAXwithdrawn(balanceWAVAX);
    }

    function withdrawLP(uint256 sharesToWithdraw) external nonReentrant {
        uint256 sharesOwned = accountShareBalance(msg.sender);
        require(sharesToWithdraw <= sharesOwned, "CycleVaultV3: Insufficient share balance for withdraw");

        uint256 amountLPforWithdraw = _withdraw(sharesToWithdraw);

        IERC20(LPtoken).safeTransfer(msg.sender, amountLPforWithdraw);
        
        emit LPwithdrawn(amountLPforWithdraw);
    }

    function _withdraw(uint256 shares) internal returns (uint256 amountLPforWithdraw) {
        amountLPforWithdraw = getLPamountForShares(shares);

        IVaultRewards(VaultRewards).withdrawToVault(shares, msg.sender);
        _burn(address(this), shares);

        emit SharesWithdrawn(shares, msg.sender);

        uint256 balanceLPinVaultBefore = balanceLPinVault();
        if (balanceLPinVaultBefore < amountLPforWithdraw) {
            uint256 amountLPToWithdrawFromStrategy = amountLPforWithdraw - balanceLPinVaultBefore;

            IStrategy(Strategy).withdraw(amountLPToWithdrawFromStrategy);
            emit LPwithdrawnFromStrategy(amountLPToWithdrawFromStrategy);

            // This logic handles a withdraw fee applied in the strategy
            // Cycle strategies will not apply a withdraw fee but this will remain in case
            //
            uint256 balanceLPinVaultAfter = balanceLPinVault();
            uint256 difference = balanceLPinVaultAfter - balanceLPinVaultBefore;
            if (difference < amountLPToWithdrawFromStrategy) {
                amountLPforWithdraw = balanceLPinVaultBefore + difference;
            }
        }
    }

    /**
     * @dev To be called when the underlying strategy is no longer viable
     * The Vault/Strategy/Rewards will be moved into decommissioned mode
     * LP from the strategy will be transfered back to the vault and deposits will be disabled
     * Reward distribution will be ended for the reward contract
     * Participants will be able to withdraw their AVAX/LP and claim remaining rewards
     *
     * WARNING: Decommissioning the strategy is irreversable
     */
    function decommissionVault() external onlyOwner {
        IStrategy(Strategy).decommissionStrategy();

        emit VaultDecommissioned(block.timestamp);

        _pause();
    }
}
