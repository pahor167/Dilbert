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

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


interface IWAVAX {
    function approve(address spender, uint amount) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface IPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IRouter {
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(address token, uint amountTokenDesired, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountAVAX);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function emergencyWithdraw(uint256 _pid) external;
    function pendingTokens(uint256 _pid, address _user) external view returns (uint256, address, string memory, uint256);
}

interface IStrategyVariables {
    function harvestFeeBasisPoints() external returns (uint256);
    function callFeeBasisPoints() external returns (uint256);
}

interface IProtocolAddresses {
    function HarvestProcessor() external returns (address);
}

interface IHarvestProcessor {
    function process() external;
}

/**
 * @title Cycle Protocol MasterChef Strategy for Trader Joe exchange
 * @dev Only JOE rewards, not double rewards
 */
contract MasterChefJoeStrategyV1 is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
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
        require(msg.sender == Vault, "MasterChefJoeStrategyV1: Caller is not the Vault");
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
        return balanceLP().add(masterChefBalanceLP());
    }

    function balanceRewardToken() public view returns (uint256) {
        return IERC20(RewardToken).balanceOf(address(this));
    }

    // Withdraws from MasterChef claim pending rewards, so better to show pending + balance
    // For basic Joe strategy, only concerned with JOE rewards, not double rewards
    function getRewardsEarned() external view returns (uint256) {
        (uint256 pendingRewards,,,) = IMasterChef(MasterChef).pendingTokens(poolID, address(this));
        return pendingRewards.add(balanceRewardToken());
    }

    /**
     * @dev Deposits will be paused when strategy has been decommissioned
     */
    function deposit() public whenNotPaused {
        uint256 balance = balanceLP();
        require(balance > 0, "MasterChefJoeStrategyV1: Deposit called with 0 balance");
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
            IMasterChef(MasterChef).withdraw(poolID, amount.sub(balance));
            balance = balanceLP();
        }

        if (balance > amount) {
            balance = amount;
        }

        IERC20(LPtoken).safeTransfer(Vault, balance);
        emit Withdraw(amount);
    }

    function harvest() external whenNotPaused nonReentrant {
        require(!Address.isContract(msg.sender), "MasterChefJoeStrategyV1: Caller is not an EOA");
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
        uint256 totalFeeBasisPoints = harvestFeeBasisPoints.add(callFeeBasisPoints);

        uint256 harvestAmountFee = harvestAmount.mul(totalFeeBasisPoints).div(BASIS_POINT_DIVISOR);

        IRouter(Router).swapExactTokensForTokens(harvestAmountFee, 0, RewardTokenToWAVAXpath, address(this), block.timestamp + 120);

        uint256 balanceWAVAX = IERC20(WAVAX).balanceOf(address(this));

        uint256 WAVAXforProcessor = balanceWAVAX.mul(harvestFeeBasisPoints).div(totalFeeBasisPoints);
        uint256 WAVAXforCaller = balanceWAVAX.sub(WAVAXforProcessor);

        address HarvestProcessor = IProtocolAddresses(ProtocolAddresses).HarvestProcessor();
        IERC20(WAVAX).safeTransfer(HarvestProcessor, WAVAXforProcessor);
        emit HarvestFeeProcessed(WAVAXforProcessor);

        IERC20(WAVAX).safeTransfer(msg.sender, WAVAXforCaller);
        emit CallFeeProcessed(WAVAXforCaller);
    }

    function _addLiquidity() internal {
        uint256 halfRewardToken = balanceRewardToken().div(2);

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
