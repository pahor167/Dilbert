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

import "./libs/PangolinLibrary.sol";
import "./libs/AMMLibrary.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IProtocolAddresses.sol";
import "./interfaces/IProcessor.sol";
import "./interfaces/IStrategyVariables.sol";
import "./interfaces/IWAVAX.sol";
import "./interfaces/IHarvestProcessor.sol";
import "./interfaces/IStakingRewards.sol";
import "./interfaces/IAVAXRewards.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/ICycle.sol";
import "./interfaces/ICycleVault.sol";


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
