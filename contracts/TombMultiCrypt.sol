// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TombVanillaCompounder.sol";

contract TombMultiCrypt is TombVanillaCompounder {

    struct Deposit {
        uint256 amount;
        uint256 phaseIndex;
    }

    address public feeCollector;

    uint256 public currentPhaseIndex = 0;
    mapping(uint256 => uint256) public TSHAREEarnedPerLPUptoWindow;
    mapping(uint256 => uint256) public LPEarnedPerTSHAREUptoWindow;

    mapping(address => Deposit[]) public LPDepositsForUser;
    mapping(address => Deposit[]) public TSHAREDepositsForUser;

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

    /*
    * USER BALANCE FUNCTIONS
    */

    function getLPBalance(address _user) external view returns (uint256) {
        uint256 balance = 0;

        // Base LP deposits
        Deposit[] storage LPDeposits = LPDepositsForUser[_user];
        for (uint256 i = 0; i < LPDeposits.length; i++) {
            balance += LPDeposits[i].amount;
        }

        uint256 lastClosedPhaseIndex = _getLastClosedPhaseIndex();
        if (lastClosedPhaseIndex == 0) return balance;

        // Plus unrealized LP gains earned by TSHAREs
        Deposit[] storage TSHAREDeposits = TSHAREDepositsForUser[_user];
        for (uint256 i = 0; i < TSHAREDeposits.length; i++) {
            Deposit storage deposit = TSHAREDeposits[i];
            balance += deposit.amount * (LPEarnedPerTSHAREUptoWindow[lastClosedPhaseIndex] - LPEarnedPerTSHAREUptoWindow[deposit.phaseIndex]);
        }

        return balance;
    }

    function getTSHAREBalance(address _user) external view returns (uint256) {
        uint256 balance = 0;

        // Base TSHARE deposits
        Deposit[] storage TSHAREDeposits = TSHAREDepositsForUser[_user];
        for (uint256 i = 0; i < TSHAREDeposits.length; i++) {
            balance += TSHAREDeposits[i].amount;
        }

        uint256 lastClosedPhaseIndex = _getLastClosedPhaseIndex();
        if (lastClosedPhaseIndex == 0) return balance;

        // Plus unrealized TSHARE gains earned by LPs
        Deposit[] storage LPDeposits = LPDepositsForUser[_user];
        for (uint256 i = 0; i < LPDeposits.length; i++) {
            Deposit storage deposit = LPDeposits[i];
            balance += deposit.amount * (TSHAREEarnedPerLPUptoWindow[lastClosedPhaseIndex] - TSHAREEarnedPerLPUptoWindow[deposit.phaseIndex]);
        }

        return balance;
    }

    /*
    * USER DEPOSIT FUNCTIONS
    */

    function depositFTM() external payable {
        // convert to LP then register into unlocked mapping
    }

    function depositTOMB(uint256 _amount) external {
        // convert to LP then register into unlocked mapping
    }

    function depositLP(uint256 _amount) external {
        // require _amount > 0
        // push new element
        // call settleAccount
    }

    function depositTSHARE(uint256 _amount) external {
        // register into unlocked mapping
    }

    /*
    * USER WITHDRAW FUNCTIONS
    * only unlocked amounts can be withdrawn
    */

    function withdrawLP(uint256 _amount) external {
        // call settleAccount
        // require lastElement's amount >= _amount
        // subtract and transfer
        // if last element's balance becomes 0, pop
    }

    function withdrawTSHARE() external {
        // pay back and deregister from unlocked mapping
        // must have enough unlocked balance
    }

    /*
    * OPERATOR FUNCTIONS TO RUN CRYPT
    */

    function lock() external onlyRole(OPERATOR_ROLE) {
        // move all unlocked LP mappings to locked LP mappings
    }

    function unlock() external onlyRole(OPERATOR_ROLE) {

    }

    /*
    * INTERNAL FUNCTIONS
    */

    // only to be called when withdrawing or depositing
    function _settleLPAccount(address _user) internal {
        // for open window, we are good if:
        //  1. array is size 1 with currentPhaseIndex

        // for closed window, we are good if
        //  1. array is size 1 with currentPhaseIndex OR
        //  2. array is size 1 with currentPhaseIndex - 1 OR
        //  3. array is size 2 with first element being currentPhaseIndex - 1 and second element being currentPhaseIndex

        // if open window
        //  if array is size 1 with currentPhaseIndex we are good, otherwise make it size 1 (with currentPhaseIndex)
        // else (closed window)
        //  if array is size 1 OR [if array is size 2 and last element's phaseIndex is currentPhaseIndex] we are good
        //  otherwise make it size 1 or 2 accordingly

    }

    function _getLastClosedPhaseIndex() internal view returns (uint256) {
        if (currentPhaseIndex == 0) return 0; // invalid value marker, check wherever invoked!

        if (_isCurrentPhaseOpen()) return currentPhaseIndex - 1;

        return currentPhaseIndex - 2;
    }

    function _isCurrentPhaseOpen() internal view returns (bool) {
        return currentPhaseIndex % 2 == 0;
    }
}
