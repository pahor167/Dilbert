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

pragma solidity ^0.8.13;

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

interface IWAVAX {
    function approve(address spender, uint amount) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function deposit() external payable;
    function withdraw(uint wad) external;
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

pragma solidity >=0.5.0;
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

library AMMLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'AMMLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'AMMLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'0bbca9af0511ad1a1da383135cf3a8d2ac620e549ef9f6ae3a4c33c2fed0af91' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'AMMLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'AMMLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'AMMLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'AMMLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'AMMLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'AMMLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'AMMLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'AMMLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

interface IVaultRewards {
    function balanceOf(address account) external view returns (uint256);
    function stakeFromVault(uint256 amount, address account) external;
    function withdrawToVault(uint256 amount, address account) external;
}

interface IMasterChefV2 {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function emergencyWithdraw(uint256 _pid) external;
    function pendingTokens(uint256 _pid, address _user) external view returns (uint256, address, string memory, uint256);
}

interface IJoeBar {
    function enter(uint256 _amount) external;
    function leave(uint256 _share) external;
}

interface IStrategyVariables {
    function harvestFeeBasisPoints() external returns (uint256);
    function callFeeBasisPoints() external returns (uint256);
}

interface IProtocolAddresses {
    function HarvestProcessor() external returns (address);
}

pragma solidity ^0.8.13;

/**
 * @title Cycle Vault for compounding xJOE using JOE rewards
 * @dev Combined legacy vault/strategy logic 
 */
contract CycleVaultxJOE is ERC20, ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public constant JOE = address(0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd);
    address public constant xJOE = address(0x57319d41F71E81F3c65F2a47CA4e001EbAFd4F33);
    address public constant WAVAX = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    address public constant Router = address(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    address public constant Factory = address(0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10);
    address public constant MasterChef = address(0xd6a4F121CA35509aF06A0Be99093d08462f53052);

    address public constant ProtocolAddresses = address(0xe97a562F03637b067324EEf459fef982BffF28d0);
    address public constant StrategyVariables = address(0xB18dCb184793be39550C6a055338286DE94c755D);

    uint256 public constant BP_DIV = 10000;
    uint256 public constant poolID = 24;

    address[] public WAVAXtoJOE = [WAVAX, JOE];
    address[] public JOEtoWAVAX = [JOE, WAVAX];

    mapping(address => bool) public authorizedContracts;

    bool public rewardsSet;
    address public VaultRewards;

    event AVAXdeposited(uint256 amountAVAX, uint256 amountxJOE, address indexed account);
    event XJOEdeposited(uint256 amountxJOE, address indexed account);
    event AVAXwithdrawn(uint256 amountAVAX, uint256 amountxJOE, address indexed account);
    event XJOEwithdrawn(uint256 amountxJOE, address indexed account);
    event Reinvest(uint256 amountxJOE, address indexed caller);
    event AuthorizedContractsUpdated(address _contract, bool status);

    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    constructor() ERC20("CycleVaultShares(TraderJoe-xJOE)", "cyVLT") {
        IERC20(WAVAX).safeApprove(Router, 0);
        IERC20(WAVAX).safeApprove(Router, MAX_INT);
        IERC20(JOE).safeApprove(Router, 0);
        IERC20(JOE).safeApprove(Router, MAX_INT);
        IERC20(JOE).safeApprove(xJOE, 0);
        IERC20(JOE).safeApprove(xJOE, MAX_INT);
        IERC20(xJOE).safeApprove(MasterChef, 0);
        IERC20(xJOE).safeApprove(MasterChef, MAX_INT);
    }

    receive() external payable {}

    function setVaultRewards(address _VaultRewards) external onlyOwner {
        require(!rewardsSet, "CycleVaultxJOE: Rewards address has already been set");
        VaultRewards = _VaultRewards;
        rewardsSet = true;
    }

    function setAuthorizedContracts(address _contract, bool status) external onlyOwner {
        authorizedContracts[_contract] = status;
        emit AuthorizedContractsUpdated(_contract, status);
    }

    modifier onlyAuthorized() {
        require(tx.origin == msg.sender || authorizedContracts[msg.sender], "CycleVaultxJOE: Caller is not EOA or authorized contract");
        _;
    }

    /**
     * @dev Balance helpers
     */
    function balancexJOE() public view returns (uint256) {
        return IERC20(xJOE).balanceOf(address(this));
    }

    function balancexJOEinMasterChef() public view returns (uint256 amount) {
        (amount,) = IMasterChefV2(MasterChef).userInfo(poolID, address(this));
    }

    function balancexJOEinSystem() public view returns (uint256) {
        return balancexJOE().add(balancexJOEinMasterChef());
    }

    function balanceLPinSystem() external view returns (uint256) { // Standard interface
        return balancexJOEinSystem();
    }

    function balanceJOE() public view returns (uint256) {
        return IERC20(JOE).balanceOf(address(this));
    }

    // Need to view shares owned through reward contract as an account will never actually hold vault shares
    function accountShareBalance(address account) public view returns (uint256) {
        return IVaultRewards(VaultRewards).balanceOf(account);
    }

    function getxJOEamountForShares(uint256 shares) public view returns (uint256) {
        return totalSupply() == 0 ? 1e18 : balancexJOEinSystem().mul(shares).div(totalSupply());
    }

    function getLPamountForShares(uint256 shares) external view returns (uint256) { // Standard interface
        return getxJOEamountForShares(shares);
    }

    function xJOEtoJOE(uint256 amountxJOE) public view returns (uint256 amountJOE) {
        uint256 xJOEbalanceJOE = IERC20(JOE).balanceOf(xJOE);
        uint256 xJOEtotalSupply = IERC20(xJOE).totalSupply();
        amountJOE = amountxJOE.mul(xJOEbalanceJOE).div(xJOEtotalSupply);
    } 

    function getAVAXquoteForxJOEamount(uint256 amountxJOE) public view returns (uint256 amountAVAX) {
        if (amountxJOE == 0) return 0;
        uint256 amountJOE = xJOEtoJOE(amountxJOE);
        (uint256 reservesWAVAX, uint256 reservesJOE) = AMMLibrary.getReserves(Factory, WAVAX, JOE);
        amountAVAX = AMMLibrary.quote(amountJOE, reservesJOE, reservesWAVAX);
    }

    function getAVAXquoteForLPamount(uint256 amountLP) external view returns (uint256) { // Standard interface
        return getAVAXquoteForxJOEamount(amountLP);
    }

    function getAVAXamountForxJOEamount(uint256 amountxJOE) public view returns (uint256 amountAVAX) {
        if (amountxJOE == 0) return 0;
        uint256 amountJOE = xJOEtoJOE(amountxJOE);
        (uint256 reservesWAVAX, uint256 reservesJOE) = AMMLibrary.getReserves(Factory, WAVAX, JOE);
        amountAVAX = AMMLibrary.getAmountOut(amountJOE, reservesJOE, reservesWAVAX);
    }

    function getAVAXamountForLPamount(uint256 amountLP) external view returns (uint256) { // Standard interface
        return getAVAXamountForxJOEamount(amountLP);
    }

    function getRewardsEarned() external view returns (uint256) {
        (uint256 pendingRewards,,,) = IMasterChefV2(MasterChef).pendingTokens(poolID, address(this));
        return pendingRewards.add(balanceJOE());
    }

    /**
     * @dev Deposit
     */
    function depositAVAX() external payable nonReentrant whenNotPaused onlyAuthorized {
        uint256 amountAVAX = msg.value;
        require(amountAVAX > 0, "CycleVaultxJOE: 0 AVAX deposit");

        uint256 previousBalancexJOEinSystem = balancexJOEinSystem();

        IWAVAX(WAVAX).deposit{value: amountAVAX}();
        uint256[] memory amounts = IRouter(Router).swapExactTokensForTokens(amountAVAX, 0, WAVAXtoJOE, address(this), block.timestamp);
        uint256 amountJOE = amounts[1];

        IJoeBar(xJOE).enter(amountJOE);
        uint256 amountxJOE = balancexJOE();

        _deposit(amountxJOE, previousBalancexJOEinSystem);

        emit AVAXdeposited(amountAVAX, amountxJOE, msg.sender);
    }

    function depositxJOE(uint256 amountxJOE) public nonReentrant whenNotPaused onlyAuthorized {
        require(amountxJOE > 0, "CycleVaultxJOE: 0 xJOE deposit");

        uint256 previousBalancexJOEinSystem = balancexJOEinSystem();

        IERC20(xJOE).safeTransferFrom(msg.sender, address(this), amountxJOE);

        _deposit(amountxJOE, previousBalancexJOEinSystem);

        emit XJOEdeposited(amountxJOE, msg.sender);
    }

    function depositLP(uint256 amount) external { // Standard interface
        depositxJOE(amount);
    } 

    function _deposit(uint256 amount, uint256 systemBalance) internal {
        uint256 shares = 0;
        
        if (totalSupply() == 0) {
            shares = amount;
        } else {
            shares = (amount.mul(totalSupply())).div(systemBalance);
        }

        _mint(address(this), shares);

        _approve(address(this), VaultRewards, shares);
        IVaultRewards(VaultRewards).stakeFromVault(shares, msg.sender);

        IMasterChefV2(MasterChef).deposit(poolID, amount);
    }

    /**
     * @dev Withdraw
     */
    function withdrawAVAX(uint256 sharesToWithdraw) external nonReentrant onlyAuthorized {
        uint256 sharesOwned = accountShareBalance(msg.sender);
        require(sharesToWithdraw <= sharesOwned, "CycleVaultxJOE: Insufficient share balance for withdraw");

        uint256 amountxJOEforWithdraw = _withdraw(sharesToWithdraw);

        uint256 balanceJOEbefore = balanceJOE();
        IJoeBar(xJOE).leave(amountxJOEforWithdraw);
        uint256 amountJOEtoSwap = balanceJOE().sub(balanceJOEbefore);
        IRouter(Router).swapExactTokensForTokens(amountJOEtoSwap, 0, JOEtoWAVAX, address(this), block.timestamp);

        uint256 balanceWAVAX = IERC20(WAVAX).balanceOf(address(this));
        IWAVAX(WAVAX).withdraw(balanceWAVAX);
        (bool success, ) = msg.sender.call{value: balanceWAVAX}("");
        require(success, "CycleVaultxJOE: Unable to transfer AVAX");

        emit AVAXwithdrawn(balanceWAVAX, amountxJOEforWithdraw, msg.sender);
    }

    function withdrawxJOE(uint256 sharesToWithdraw) public nonReentrant onlyAuthorized {
        uint256 sharesOwned = accountShareBalance(msg.sender);
        require(sharesToWithdraw <= sharesOwned, "CycleVaultxJOE: Insufficient share balance for withdraw");

        uint256 amountxJOEforWithdraw = _withdraw(sharesToWithdraw);

        IERC20(xJOE).safeTransfer(msg.sender, amountxJOEforWithdraw);

        emit XJOEwithdrawn(amountxJOEforWithdraw, msg.sender);
    }

    function withdrawLP(uint256 sharesToWithdraw) external { // Standard interface
        withdrawxJOE(sharesToWithdraw);
    }

    function _withdraw(uint256 shares) internal returns (uint256 amountxJOEforWithdraw) {
        amountxJOEforWithdraw = getxJOEamountForShares(shares);

        IVaultRewards(VaultRewards).withdrawToVault(shares, msg.sender);
        _burn(address(this), shares);

        uint256 balancexJOEinVault = balancexJOE();
        if (balancexJOEinVault < amountxJOEforWithdraw) {
            uint256 amountxJOEtoWithdrawFromMC = amountxJOEforWithdraw.sub(balancexJOEinVault);
            IMasterChefV2(MasterChef).withdraw(poolID, amountxJOEtoWithdrawFromMC);
        }
    }

    /**
     * @dev Reinvest
     */
    function reinvest() public nonReentrant whenNotPaused {
        require(!Address.isContract(msg.sender), "CycleVaultxJOE: Caller is not an EOA");

        IMasterChefV2(MasterChef).deposit(poolID, 0);

        _processFees();
        _reinvestRewards();
    }

    function harvest() external { // Standard interface
        reinvest();
    }

    function _processFees() internal {
        uint256 reinvestBP = IStrategyVariables(StrategyVariables).harvestFeeBasisPoints();
        uint256 kickbackBP = IStrategyVariables(StrategyVariables).callFeeBasisPoints();
        uint256 totalFeeBP = reinvestBP.add(kickbackBP);

        uint256 amountJOEforFees = balanceJOE().mul(totalFeeBP).div(BP_DIV);
        IRouter(Router).swapExactTokensForTokens(amountJOEforFees, 0, JOEtoWAVAX, address(this), block.timestamp);

        uint256 balanceWAVAX = IERC20(WAVAX).balanceOf(address(this));
        uint256 WAVAXforProcessor = balanceWAVAX.mul(reinvestBP).div(totalFeeBP);
        uint256 WAVAXforCaller = balanceWAVAX.sub(WAVAXforProcessor);

        address HarvestProcessor = IProtocolAddresses(ProtocolAddresses).HarvestProcessor();
        IERC20(WAVAX).safeTransfer(HarvestProcessor, WAVAXforProcessor);
        IERC20(WAVAX).safeTransfer(msg.sender, WAVAXforCaller);
    }

    function _reinvestRewards() internal {
        IJoeBar(xJOE).enter(balanceJOE());

        uint256 amountxJOE = balancexJOE();
        IMasterChefV2(MasterChef).deposit(poolID, amountxJOE);

        emit Reinvest(amountxJOE, msg.sender);
    }

    /**
     * @dev Decommission
     */
    function decommission() external onlyOwner {
        IMasterChefV2(MasterChef).emergencyWithdraw(poolID);
        _pause();
    }

}
