// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";

contract Cycle is ERC20, Ownable, ReentrancyGuard {

    address public Distributor;
    address public Timelock;

    uint256 public distributionPhase = 1;
    uint256 public scalingFactor = 100;

    uint256 public constant FACTOR_DIVISOR = 100;

    mapping (address => uint256) public authorizedAmount;

    event CycleRun(address indexed caller, uint256 amountIn, uint256 amountOut);
    event ScalingFactorUpdated(uint256 scalingFactor);
    event DistributorUpdated(address Distributor);
    event TimelockUpdated(address Timelock);

    constructor() ERC20("Cycle Token", "CYCLE") {
        _mint(msg.sender, 30000e18);
        _mint(address(this), 270000e18);
    }

    modifier onlyTimelock() {
        require(msg.sender == Timelock, "Cycle: Caller is not the Timelock");
        _;
    }

    function setTimelock(address _Timelock) external onlyOwner {
        Timelock = _Timelock;
        emit TimelockUpdated(Timelock);
    }

    function setDistributor(address _Distributor) external onlyTimelock {
        Distributor = _Distributor;
        emit DistributorUpdated(Distributor);
    }

    function setScalingFactor(uint256 _scalingFactor) external onlyTimelock {
        scalingFactor = _scalingFactor;
        emit ScalingFactorUpdated(scalingFactor);
    }

    /**
     * @dev Safeguard from accidentally calling {cycle}
     * {cycle} consumes the input CYCLE tokens of the caller
     * this forces a preconfirmation to avoid unwanted loss
     */
    function authorize(uint256 amount) external nonReentrant {
        authorizedAmount[msg.sender] = amount;
    }

    /**
     * @dev Any contract/EOA can call to run {cycle}
     * {amountIn} scaled by the scaling factor produces {amountOut}
     */
    function cycle(uint256 amountIn) external nonReentrant {
        require(amountIn > 0, "Cycle: 0 amountIn sent");
        require(authorizedAmount[msg.sender] >= amountIn, "Cycle: Input amount has not been authorized");

        authorizedAmount[msg.sender] = authorizedAmount[msg.sender] - amountIn;

        uint256 amountOut;

        if (distributionPhase == 1) {
            uint256 balance = balanceOf(address(this));
            uint256 SF = (balance / 1e18) / 900 + 300;
            amountOut = amountIn * SF / FACTOR_DIVISOR;

            _transfer(msg.sender, address(this), amountIn);
            balance = balanceOf(address(this));

            if (amountOut > balance) {
                _transfer(address(this), Distributor, balance);
                distributionPhase = 2;
            } else {
                _transfer(address(this), Distributor, amountOut);
            }
        } else if (distributionPhase == 2) {
            _burn(msg.sender, amountIn);
            amountOut = amountIn * scalingFactor / FACTOR_DIVISOR;
            _mint(Distributor, amountOut);
        }

        emit CycleRun(msg.sender, amountIn, amountOut);
    }

}
