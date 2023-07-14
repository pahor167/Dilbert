// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";

contract ProtocolAddresses is Ownable {
    address public Distributor;
    address public HarvestProcessor;

    address public immutable CYCLE = address(0x81440C939f2C1E34fc7048E518a637205A632a74);

    event DistributorAddressUpdated(address Distributor);
    event HarvestProcessorAddressUpdated(address HarvestProcessor);

    function setDistributor(address _Distributor) external onlyOwner {
        Distributor = _Distributor;
        emit DistributorAddressUpdated(Distributor);
    }
    function setHarvestProcessor(address _HarvestProcessor) external onlyOwner {
        HarvestProcessor = _HarvestProcessor;
        emit HarvestProcessorAddressUpdated(HarvestProcessor);
    }
}
