// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IProtocolAddresses {
    function HarvestProcessor() external returns (address);
    function Distributor() external view returns (address);
}
