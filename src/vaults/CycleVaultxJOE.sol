// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/utils/Address.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/access/Ownable.sol";

import "../libs/SafeMath.sol";
import "../libs/AMMLibrary.sol";
import "../interfaces/IRouter.sol";
import "../interfaces/IStrategyVariables.sol";
import "../interfaces/IWAVAX.sol";
import "../interfaces/IVaultRewards.sol";
import "../interfaces/IProtocolAddresses.sol";
import "../interfaces/IJoeBar.sol";
import "../interfaces/IMasterChefV2.sol";

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
