// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/utils/Address.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/access/Ownable.sol";

import "../libs/AMMLibrary.sol";
import "../interfaces/IRouter.sol";
import "../interfaces/IProtocolAddresses.sol";
import "../interfaces/IStrategyVariables.sol";
import "../interfaces/IWAVAX.sol";
import "../interfaces/IStakingRewards.sol";
import "../interfaces/IVaultRewards.sol";

/**
 * @title Cycle Vault for compounding PNG using AVAX rewards
 * @dev Combined legacy vault/strategy logic 
 */
contract CycleVaultPNG is ERC20, ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    address public constant PNG = address(0x60781C2586D68229fde47564546784ab3fACA982);
    address public constant WAVAX = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    address public constant Router = address(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106);
    address public constant Factory = address(0xefa94DE7a4656D787667C749f7E1223D71E9FD88);
    address public constant StakingRewards = address(0xD49B406A7A29D64e081164F6C3353C599A2EeAE9);

    address public constant ProtocolAddresses = address(0xe97a562F03637b067324EEf459fef982BffF28d0);
    address public constant StrategyVariables = address(0xB18dCb184793be39550C6a055338286DE94c755D);

    uint256 public constant BP_DIV = 10000;

    address[] public WAVAXtoPNG = [WAVAX, PNG];
    address[] public PNGtoWAVAX = [PNG, WAVAX];

    mapping(address => bool) public authorizedContracts;

    bool public rewardsSet;
    address public VaultRewards;

    event AVAXdeposited(uint256 amountAVAX, uint256 amountPNG, address indexed account);
    event PNGdeposited(uint256 amountPNG, address indexed account);
    event AVAXwithdrawn(uint256 amountAVAX, uint256 amountPNG, address indexed account);
    event PNGwithdrawn(uint256 amountPNG, address indexed account);
    event Reinvest(uint256 amountPNG, address indexed caller);
    event AuthorizedContractsUpdated(address _contract, bool status);

    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    constructor() ERC20("CycleVaultShares(Pangolin-PNG)", "cyVLT") {
        IERC20(WAVAX).safeApprove(Router, 0);
        IERC20(WAVAX).safeApprove(Router, MAX_INT);
        IERC20(PNG).safeApprove(Router, 0);
        IERC20(PNG).safeApprove(Router, MAX_INT);
        IERC20(PNG).safeApprove(StakingRewards, 0);
        IERC20(PNG).safeApprove(StakingRewards, MAX_INT);
    }

    receive() external payable {}

    function setVaultRewards(address _VaultRewards) external onlyOwner {
        require(!rewardsSet, "CycleVaultPNG: Rewards address has already been set");
        VaultRewards = _VaultRewards;
        rewardsSet = true;
    }

    function setAuthorizedContracts(address _contract, bool status) external onlyOwner {
        authorizedContracts[_contract] = status;
        emit AuthorizedContractsUpdated(_contract, status);
    }

    modifier onlyAuthorized() {
        require(tx.origin == msg.sender || authorizedContracts[msg.sender], "CycleVaultPNG: Caller is not EOA or authorized contract");
        _;
    }

    /**
     * @dev Balance helpers
     */
    function balancePNG() public view returns (uint256) {
        return IERC20(PNG).balanceOf(address(this));
    }

    function balancePNGinStakingRewards() public view returns (uint256) {
        return IStakingRewards(StakingRewards).balanceOf(address(this));
    }

    function balancePNGinSystem() public view returns (uint256) {
        return balancePNG() + (balancePNGinStakingRewards());
    }

    function balanceLPinSystem() external view returns (uint256) { // Standard interface
        return balancePNGinSystem();
    }

    function balanceWAVAX() public view returns (uint256) {
        return IERC20(WAVAX).balanceOf(address(this));
    }

    // Need to view shares owned through reward contract as an account will never actually hold vault shares
    function accountShareBalance(address account) public view returns (uint256) {
        return IVaultRewards(VaultRewards).balanceOf(account);
    }

    function getPNGamountForShares(uint256 shares) public view returns (uint256) {
        return totalSupply() == 0 ? 1e18 : balancePNGinSystem() * (shares) / (totalSupply());
    }

    function getLPamountForShares(uint256 shares) external view returns (uint256) { // Standard interface
        return getPNGamountForShares(shares);
    }

    function getAVAXquoteForPNGamount(uint256 amountPNG) public view returns (uint256 amountAVAX) {
        if (amountPNG == 0) return 0;
        (uint256 reservesWAVAX, uint256 reservesPNG) = AMMLibrary.getReserves(Factory, WAVAX, PNG);
        amountAVAX = AMMLibrary.quote(amountPNG, reservesPNG, reservesWAVAX);
    }

    function getAVAXquoteForLPamount(uint256 amountLP) external view returns (uint256) { // Standard interface
        return getAVAXquoteForPNGamount(amountLP);
    }

    function getAVAXamountForPNGamount(uint256 amountPNG) public view returns (uint256 amountAVAX) {
        if (amountPNG == 0) return 0;
        (uint256 reservesWAVAX, uint256 reservesPNG) = AMMLibrary.getReserves(Factory, WAVAX, PNG);
        amountAVAX = AMMLibrary.getAmountOut(amountPNG, reservesPNG, reservesWAVAX);
    }

    function getAVAXamountForLPamount(uint256 amountLP) external view returns (uint256) { // Standard interface
        return getAVAXamountForPNGamount(amountLP);
    }

    function getRewardsEarned() external view returns (uint256) {
        return IStakingRewards(StakingRewards).earned(address(this));
    }

    /**
     * @dev Deposit
     */
    function depositAVAX() external payable nonReentrant whenNotPaused onlyAuthorized {
        uint256 amountAVAX = msg.value;
        require(amountAVAX > 0, "CycleVaultPNG: 0 AVAX deposit");

        uint256 previousBalancePNGinSystem = balancePNGinSystem();

        IWAVAX(WAVAX).deposit{value: amountAVAX}();
        uint256[] memory amounts = IRouter(Router).swapExactTokensForTokens(amountAVAX, 0, WAVAXtoPNG, address(this), block.timestamp);
        uint256 amountPNG = amounts[1];

        _deposit(amountPNG, previousBalancePNGinSystem);

        emit AVAXdeposited(amountAVAX, amountPNG, msg.sender);
    }

    function depositPNG(uint256 amountPNG) public nonReentrant whenNotPaused onlyAuthorized {
        require(amountPNG > 0, "CycleVaultPNG: 0 PNG deposit");

        uint256 previousBalancePNGinSystem = balancePNGinSystem();

        IERC20(PNG).safeTransferFrom(msg.sender, address(this), amountPNG);

        _deposit(amountPNG, previousBalancePNGinSystem);

        emit PNGdeposited(amountPNG, msg.sender);
    }

    function depositLP(uint256 amount) external { // Standard interface
        depositPNG(amount);
    } 

    function _deposit(uint256 amount, uint256 systemBalance) internal {
        uint256 shares = 0;
        
        if (totalSupply() == 0) {
            shares = amount;
        } else {
            shares = (amount * (totalSupply())) / (systemBalance);
        }

        _mint(address(this), shares);

        _approve(address(this), VaultRewards, shares);
        IVaultRewards(VaultRewards).stakeFromVault(shares, msg.sender);

        IStakingRewards(StakingRewards).stake(amount);
    }

    /**
     * @dev Withdraw
     */
    function withdrawAVAX(uint256 sharesToWithdraw) external nonReentrant onlyAuthorized {
        uint256 sharesOwned = accountShareBalance(msg.sender);
        require(sharesToWithdraw <= sharesOwned, "CycleVaultPNG: Insufficient share balance for withdraw");

        uint256 amountPNGwithdrawn = _withdraw(sharesToWithdraw);

        IRouter(Router).swapExactTokensForTokens(amountPNGwithdrawn, 0, PNGtoWAVAX, address(this), block.timestamp);

        uint256 balWAVAX = balanceWAVAX();
        IWAVAX(WAVAX).withdraw(balWAVAX);
        (bool success, ) = msg.sender.call{value: balWAVAX}("");
        require(success, "CycleVaultPNG: Unable to transfer AVAX");

        emit AVAXwithdrawn(balWAVAX, amountPNGwithdrawn, msg.sender);
    }

    function withdrawPNG(uint256 sharesToWithdraw) public nonReentrant onlyAuthorized {
        uint256 sharesOwned = accountShareBalance(msg.sender);
        require(sharesToWithdraw <= sharesOwned, "CycleVaultPNG: Insufficient share balance for withdraw");

        uint256 amountPNGwithdrawn = _withdraw(sharesToWithdraw);

        IERC20(PNG).safeTransfer(msg.sender, amountPNGwithdrawn);

        emit PNGwithdrawn(amountPNGwithdrawn, msg.sender);
    }

    function withdrawLP(uint256 sharesToWithdraw) external { // Standard interface
        withdrawPNG(sharesToWithdraw);
    }

    function _withdraw(uint256 shares) internal returns (uint256 amountPNGforWithdraw) {
        amountPNGforWithdraw = getPNGamountForShares(shares);

        IVaultRewards(VaultRewards).withdrawToVault(shares, msg.sender);
        _burn(address(this), shares);

        uint256 balancePNGinVault = balancePNG();
        if (balancePNGinVault < amountPNGforWithdraw) {
            uint256 amountPNGtoWithdrawFromSR = amountPNGforWithdraw - (balancePNGinVault);
            IStakingRewards(StakingRewards).withdraw(amountPNGtoWithdrawFromSR);
        }
    }

    /**
     * @dev Reinvest
     */
    function reinvest() public nonReentrant whenNotPaused {
        require(!Address.isContract(msg.sender), "CycleVaultPNG: Caller is not an EOA");

        IStakingRewards(StakingRewards).getReward();

        _processFees();
        _reinvestRewards();
    }

    function harvest() external { // Standard interface
        reinvest();
    }

    function _processFees() internal {
        uint256 reinvestBP = IStrategyVariables(StrategyVariables).harvestFeeBasisPoints();
        uint256 kickbackBP = IStrategyVariables(StrategyVariables).callFeeBasisPoints();
        uint256 totalFeeBP = reinvestBP + (kickbackBP);

        uint256 amountWAVAXforFees = balanceWAVAX() * (totalFeeBP) / (BP_DIV);

        uint256 WAVAXforProcessor = amountWAVAXforFees * (reinvestBP) / (totalFeeBP);
        uint256 WAVAXforCaller = amountWAVAXforFees - (WAVAXforProcessor);

        address Processor = IProtocolAddresses(ProtocolAddresses).HarvestProcessor();
        IERC20(WAVAX).safeTransfer(Processor, WAVAXforProcessor);
        IERC20(WAVAX).safeTransfer(msg.sender, WAVAXforCaller);
    }

    function _reinvestRewards() internal {
        uint256 balWAVAX = balanceWAVAX();
        
        uint256[] memory amounts = IRouter(Router).swapExactTokensForTokens(balWAVAX, 0, WAVAXtoPNG, address(this), block.timestamp);
        uint256 amountPNG = amounts[1];
        
        IStakingRewards(StakingRewards).stake(amountPNG);

        emit Reinvest(amountPNG, msg.sender);
    }

    /**
     * @dev Decommission
     */
    function decommission() external onlyOwner {
        uint256 amountPNGstaked = balancePNGinStakingRewards();
        IStakingRewards(StakingRewards).withdraw(amountPNGstaked);
        _pause();
    }

}
