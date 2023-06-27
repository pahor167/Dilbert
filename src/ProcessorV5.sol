// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin-contracts/utils/Context.sol";
import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/utils/Address.sol";
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

interface ICycle {
    function cycle(uint256 amountIn) external;
    function authorize(uint256 amount) external;
}

interface IWAVAX {
    function deposit() external payable;
}

interface IStakingRewards {
    function notifyRewardAmount(uint256 reward) external;
}

/**
 * @title Processor V5
 * @dev Transfer to AVAX rewards, team and control daily emission
 */
contract ProcessorV5 is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

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
        uint256 teamFee = balWAVAX.mul(teamBP).div(BP_DIV);
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
