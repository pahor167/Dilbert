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
                hex'40231f6b438bce0797c9ada29b718a87ea0a5cea3fe9a771abdd76bd41a3e545' // init code hash
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

interface IStrategy {
    function deposit() external;
    function withdraw(uint256) external;
    function balanceLPinStrategy() external view returns (uint256);
    function decommissionStrategy() external;
}

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
