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

interface IAVAXRewards {
    function balanceOf(address account) external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
}

/**
 * @title xCycle
 * @dev Compounding CYCLE using protocol AVAX revenue
 */
contract xCycle is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public constant CYCLE = address(0x81440C939f2C1E34fc7048E518a637205A632a74);
    address public constant WAVAX = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    address public constant Router = address(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106);
    address public constant AVAXRewards = address(0x6140D3ED2426cbB24f07D884106D9018d49d9101);

    uint256 public constant BP_DIV = 10000;
    uint256 public kickbackBP = 100;

    address[] public swapPath = [WAVAX, CYCLE];

    event Deposit(address indexed account, uint256 amountCYCLE, uint256 xCYCLEreceived);
    event Withdraw(address indexed account, uint256 xCYCLEredeemed, uint256 CYCLEreceived);
    event Reinvest(uint256 xCYCLEvalue, uint256 timestamp);

    constructor() ERC20("xCycle", "xCYCLE") {}

    receive() external payable {}

    /**
     * @dev Owner controlled functions
     */
    function setKickbackBP(uint256 _kickbackBP) external onlyOwner {
        kickbackBP = _kickbackBP;
    }

    /**
     * @dev Helpers
     */
    function getBalanceCYCLE() public view returns (uint256) {
        return IERC20(CYCLE).balanceOf(address(this));
    }

    function getStakedCYCLE() public view returns (uint256) {
        return IAVAXRewards(AVAXRewards).balanceOf(address(this));
    }

    function getBalanceAVAX() public view returns (uint256) {
        return address(this).balance;
    }

    function xCYCLEtoCYCLE(uint256 xCYCLEamount) public view returns (uint256) {
        uint256 xCYCLEsupply = totalSupply();
        return xCYCLEsupply == 0 ? 0 : getStakedCYCLE().mul(xCYCLEamount).div(xCYCLEsupply);
    }

    function getAccountCYCLE(address account) external view returns (uint256) {
        return xCYCLEtoCYCLE(balanceOf(account));
    }

    function getRewardsEarned() external view returns (uint256) {
        return IAVAXRewards(AVAXRewards).earned(address(this));
    }

    function getKickbackAmount() external view returns (uint256) {
        uint256 rewardsEarned = IAVAXRewards(AVAXRewards).earned(address(this));
        return rewardsEarned.mul(kickbackBP).div(BP_DIV);
    }

    /**
     * @dev Public mutative functions
     */
    function deposit(uint256 amountCYCLE) external nonReentrant {
        require(amountCYCLE > 0, "xCycle: 0 CYCLE deposit");

        uint256 xCYCLEtoMint = 0;
        uint256 xCYCLEsupply = totalSupply();

        IERC20(CYCLE).safeTransferFrom(msg.sender, address(this), amountCYCLE);

        xCYCLEtoMint = xCYCLEsupply == 0 ? amountCYCLE : amountCYCLE.mul(xCYCLEsupply).div(getStakedCYCLE());

        _mint(msg.sender, xCYCLEtoMint);

        IERC20(CYCLE).safeIncreaseAllowance(AVAXRewards, amountCYCLE);
        IAVAXRewards(AVAXRewards).stake(amountCYCLE);

        emit Deposit(msg.sender, amountCYCLE, xCYCLEtoMint);
    }

    function withdraw(uint256 xCYCLEtoRedeem) external nonReentrant {
        require(xCYCLEtoRedeem <= balanceOf(msg.sender), "xCycle: Insufficient xCYCLE balance");

        uint256 amountCYCLEtoWithdraw = xCYCLEtoCYCLE(xCYCLEtoRedeem);

        _burn(msg.sender, xCYCLEtoRedeem);

        IAVAXRewards(AVAXRewards).withdraw(amountCYCLEtoWithdraw);
        
        IERC20(CYCLE).safeTransfer(msg.sender, amountCYCLEtoWithdraw);

        emit Withdraw(msg.sender, xCYCLEtoRedeem, amountCYCLEtoWithdraw);
    }

    function reinvest() external nonReentrant {
        require(!Address.isContract(msg.sender), "xCycle: Caller is not an EOA");

        IAVAXRewards(AVAXRewards).getReward();

        uint256 balanceAVAX = getBalanceAVAX();
        uint256 kickbackAmount = balanceAVAX.mul(kickbackBP).div(BP_DIV);
        (bool success, ) = msg.sender.call{value: kickbackAmount}("");
        require(success, "xCycle: Unable to transfer AVAX");

        balanceAVAX = getBalanceAVAX();
        IRouter(Router).swapExactAVAXForTokens{value: balanceAVAX}(0, swapPath, address(this), block.timestamp);

        uint256 balanceCYCLE = getBalanceCYCLE();
        IERC20(CYCLE).safeIncreaseAllowance(AVAXRewards, balanceCYCLE);
        IAVAXRewards(AVAXRewards).stake(balanceCYCLE);

        uint256 xCYCLEvalue = xCYCLEtoCYCLE(1e18);

        emit Reinvest(xCYCLEvalue, block.timestamp);
    }

}
