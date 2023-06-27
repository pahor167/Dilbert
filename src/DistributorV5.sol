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


interface IPangolinPair {
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

library PangolinLibrary {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PangolinLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PangolinLibrary: ZERO_ADDRESS');
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
        (uint reserve0, uint reserve1,) = IPangolinPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PangolinLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PangolinLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PangolinLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PangolinLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PangolinLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PangolinLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = reserveOut - amountOut * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PangolinLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PangolinLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

interface IRouter {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IWAVAX {
    function approve(address spender, uint amount) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface IStakingRewards {
    function stakingToken() external view returns (address);
    function totalSupply() external view returns (uint256);
    function notifyRewardAmount(uint256 reward) external;
}

interface ICycleVault {
    function balanceLPinSystem() external view returns (uint256);
    function getAVAXquoteForLPamount(uint256 amountLP) external view returns (uint256);
}

interface IProcessor {
    function emission() external view returns (uint256);
}

interface IProtocolAddresses {
    function HarvestProcessor() external view returns (address);
}

/**
 * @title Distributor V5
 * @dev Cycle vault reward distribution logic
 */
contract DistributorV5 is Ownable {
    using SafeERC20 for IERC20;

    address public ProtocolAddresses;
    address public Proxy;
    address public CoreRewards;

    uint256 public distributionCost;
    uint256 public coreRewardsBasisPoints;

    address public constant CYCLE = address(0x81440C939f2C1E34fc7048E518a637205A632a74);
    address public constant WAVAX = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    address public constant Factory = address(0xefa94DE7a4656D787667C749f7E1223D71E9FD88);
    address public constant Router = address(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106);

    address[] public swapPath = [CYCLE, WAVAX];

    uint256 public constant BP_DIVISOR = 10000;

    struct RewardData {
        address StakingRewards;
        uint256 weight;
    }

    struct NormalizedRewardData {
        address StakingRewards;
        uint256 normalizedTVL;
    }

    RewardData[] public rewards;

    event RewardContractAdded(address StakingRewards);
    event RewardContractDeleted(address StakingRewards);
    event RewardWeightUpdated(address StakingRewards, uint256 weight);
    event CycleDistributedTotal(uint256 amount);
    event CycleDistributed(address StakingRewards, uint256 amount);
    event DistributionCostUpdated(uint256 distributionCost);
    event ProtocolAddressesUpdated(address ProtocolAddresses);
    event ProxyUpdated(address Proxy);
    event CoreRewardsUpdated(address CoreRewards);
    event CoreRewardsBasisPointsUpdated(uint256 coreRewardsBasisPoints);

    constructor(uint256 _distributionCost, uint256 _coreRewardsBasisPoints) {
        distributionCost = _distributionCost;
        coreRewardsBasisPoints = _coreRewardsBasisPoints;
        emit DistributionCostUpdated(distributionCost);
        emit CoreRewardsBasisPointsUpdated(coreRewardsBasisPoints);
    }

    receive() external payable {}

    modifier onlyProxy() {
        require(msg.sender == Proxy, "DistributorV5: Caller must be the Proxy");
        _;
    }

    /**
     * @dev External address management
     */
    function setProtocolAddresses(address _ProtocolAddresses) external onlyOwner {
        ProtocolAddresses = _ProtocolAddresses;
        emit ProtocolAddressesUpdated(ProtocolAddresses);
    }

    function setProxy(address _Proxy) external onlyOwner {
        Proxy = _Proxy;
        emit ProxyUpdated(Proxy);
    }

    function setCoreRewards(address _CoreRewards) external onlyOwner {
        CoreRewards = _CoreRewards;
        emit CoreRewardsUpdated(CoreRewards);
    }

    /**
     * @dev Vault reward data management
     *
     * Do not add CoreRewards to the vault rewards array
     */
    function addRewardData(address StakingRewards) external onlyOwner {
        // Initialize weight at 10 to allow unidirectional adjustment
        for (uint i; i < rewards.length; i++) {
            require(rewards[i].StakingRewards != StakingRewards, "Distributor: Reward contract has already been added");
        }
        rewards.push(RewardData(StakingRewards, 10));
        emit RewardContractAdded(StakingRewards);
    }

    function deleteRewardData(uint256 index) external onlyOwner {
        require(index < rewards.length, "Distributor: Index out of bounds");
        address StakingRewards = rewards[index].StakingRewards;
        for (uint i = index; i < rewards.length - 1; i++) {
            rewards[i] = rewards[i + 1];
        }
        rewards.pop();
        emit RewardContractDeleted(StakingRewards);
    }

    function updateRewardWeight(address StakingRewards, uint256 weight) external onlyOwner {
        for (uint i; i < rewards.length; i++) {
            if (rewards[i].StakingRewards == StakingRewards) {
                rewards[i].weight = weight;
                emit RewardWeightUpdated(StakingRewards, weight);
                break;
            }
        }
    }

    /**
     * @dev Core reward data management
     */
    function setCoreRewardsBasisPoints(uint256 _coreRewardsBasisPoints) external onlyOwner {
        require(_coreRewardsBasisPoints < BP_DIVISOR, "DistributorV5: Basis Points out of bounds");
        coreRewardsBasisPoints = _coreRewardsBasisPoints;
        emit CoreRewardsBasisPointsUpdated(coreRewardsBasisPoints);
    }

    /**
     * @dev Set the approximate current cost of the distribute function in wei
     * @dev Will need to be updated whenever reward array is updated
     */
    function setDistributionCost(uint256 _distributionCost) external onlyOwner {
        distributionCost = _distributionCost;
        emit DistributionCostUpdated(distributionCost);
    }

    /**
     * @dev Reward data getters
     */
    function getRewardWeight(address StakingRewards) external view returns (uint256) {
        for (uint i; i < rewards.length; i++) {
            if (rewards[i].StakingRewards == StakingRewards) {
                return rewards[i].weight;
            }
        }
        revert("StakingReward contract does not exist in rewards collection");
    }

    function getRewardIndex(address StakingRewards) external view returns (uint256) {
        for (uint i; i < rewards.length; i++) {
            if (rewards[i].StakingRewards == StakingRewards) {
                return i;
            }
        }
        revert("StakingReward contract does not exist in rewards collection");
    }

    function getTotalWeight() public view returns (uint256 totalWeight) {
        for (uint i; i < rewards.length; i++) {
            totalWeight = totalWeight + rewards[i].weight;
        }
    }

    function getVaultRewardsCount() external view returns (uint256) {
        return rewards.length;
    }

    function cycleBalance() public view returns (uint256) {
        return IERC20(CYCLE).balanceOf(address(this));
    }

    /**
     * @dev TVL helpers
     */
    function getCoreRewardsTVL() public view returns (uint256) {
        address coreLP = IStakingRewards(CoreRewards).stakingToken();
        uint256 totalSupplyCoreLP = IERC20(coreLP).totalSupply();
        uint256 amountCoreLPstaked = IStakingRewards(CoreRewards).totalSupply();
        (uint256 reservesWAVAX,) = PangolinLibrary.getReserves(Factory, WAVAX, CYCLE);
        uint256 amountAVAX = reservesWAVAX * (amountCoreLPstaked) / totalSupplyCoreLP;
        // AVAX + CYCLE 
        return amountAVAX + (2);
    }

    function getVaultTVL(address StakingRewards) public view returns (uint256) {
        address Vault = IStakingRewards(StakingRewards).stakingToken();
        uint256 totalLPinVault = ICycleVault(Vault).balanceLPinSystem();
        return ICycleVault(Vault).getAVAXquoteForLPamount(totalLPinVault);
    }

    /**
     * @dev Call fee kickback logic, sending {distributionCost} in AVAX to caller
     */
    function _processKickback(address caller) internal {
        (uint256 reservesWAVAX, uint256 reservesCYCLE) = PangolinLibrary.getReserves(Factory, WAVAX, CYCLE);
        uint256 amountCYCLEtoSwap = PangolinLibrary.getAmountIn(distributionCost, reservesCYCLE, reservesWAVAX);

        IERC20(CYCLE).safeIncreaseAllowance(Router, amountCYCLEtoSwap);
        IRouter(Router).swapExactTokensForTokens(amountCYCLEtoSwap, 0, swapPath, address(this), block.timestamp + 120);

        uint256 balanceWAVAX = IERC20(WAVAX).balanceOf(address(this));
        IWAVAX(WAVAX).withdraw(balanceWAVAX);

        (bool success, ) = caller.call{value: balanceWAVAX}("");
        require(success, "DistributorV5: Unable to transfer AVAX");
    }

    /**
     * @dev Distribution function
     *
     * Normalizes output based on correlated AVAX TVL of Vaults, applying custom weighting
     * Core Rewards takes a fixed percent of the distribution
     *
     */
    function distribute(address caller) external onlyProxy {
        uint256 amountToDistribute = cycleBalance();
        require(amountToDistribute > 0, "DistributorV5: No CYCLE to distribute");

        // Send emission amount back to processor
        address Processor = IProtocolAddresses(ProtocolAddresses).HarvestProcessor();
        uint256 emissionAmount = IProcessor(Processor).emission();
        uint256 processorBalance = IERC20(CYCLE).balanceOf(Processor);
        if (processorBalance < emissionAmount) {
            IERC20(CYCLE).safeTransfer(Processor, emissionAmount - processorBalance);
        }

        _processKickback(caller);

        // CYCLE is used for the caller kickback, read balance again
        amountToDistribute = cycleBalance();
        emit CycleDistributedTotal(amountToDistribute);

        // Core Rewards distribution
        uint256 amountForCoreRewards = amountToDistribute * coreRewardsBasisPoints / BP_DIVISOR;
        IERC20(CYCLE).safeTransfer(CoreRewards, amountForCoreRewards);
        IStakingRewards(CoreRewards).notifyRewardAmount(amountForCoreRewards);
        emit CycleDistributed(CoreRewards, amountForCoreRewards);

        amountToDistribute = cycleBalance();

        uint256 totalNormalizedTVL;
        NormalizedRewardData[] memory normalizedRewards = new NormalizedRewardData[](rewards.length);

        // Loop through the vaults, storing the weight normalized TVL
        for (uint i; i < rewards.length; i++) {
            uint256 vaultTVL = getVaultTVL(rewards[i].StakingRewards);
            uint256 vaultTVLnormalized = vaultTVL * rewards[i].weight;
            totalNormalizedTVL = totalNormalizedTVL + (vaultTVLnormalized);
            normalizedRewards[i].normalizedTVL = vaultTVLnormalized;
            normalizedRewards[i].StakingRewards = rewards[i].StakingRewards;
        }

        for (uint i; i < normalizedRewards.length; i++) {
            address destination = normalizedRewards[i].StakingRewards;
            uint256 amountToSend;
            if (i == normalizedRewards.length - 1) {
                amountToSend = cycleBalance(); // send remainder to last vault reward contract
            } else {
                amountToSend = amountToDistribute * (normalizedRewards[i].normalizedTVL) / (totalNormalizedTVL);
            }
            IERC20(CYCLE).safeTransfer(destination, amountToSend);
            IStakingRewards(destination).notifyRewardAmount(amountToSend);
            emit CycleDistributed(destination, amountToSend);
        }
        
    }

}
