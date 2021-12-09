// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TombVanillaCompounder.sol";

contract TombMultiCrypt is TombVanillaCompounder {
    address public feeCollector;

    constructor(
        address _tomb,
        address _tshare,
        address _spookyTombFtmLP,
        address _masonry,
        address _cemetery,
        address _spookyRouter,
        address _operator,
        address _feeCollector
    ) TombVanillaCompounder(
        _tomb,
        _tshare,
        _spookyTombFtmLP,
        _masonry,
        _cemetery,
        _spookyRouter,
        _operator
    ) { 
        feeCollector = _feeCollector;
    }

    function setFeeCollector(address _feeCollector) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeCollector = _feeCollector;
    }
}
