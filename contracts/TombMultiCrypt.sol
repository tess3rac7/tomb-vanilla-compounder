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

    /*
    * the "phaseIndex" for each item in the array will be unique.
    * this is because withdraw/deposit operations within the same phase
    * operate on the same Deposit object
    */
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

    function getLPBalance(address _user) public view returns (uint256) {
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

    function getWithdrawableLPBalance(address _user) external view returns (uint256) {
        if (_isCurrentPhaseOpen()) return getLPBalance(_user);

        // if current phase is closed only deposits made in the current phase can be withdrawn
        uint256 withdrawableBalance = 0;
        Deposit[] storage LPDeposits = LPDepositsForUser[_user];
        if (LPDeposits.length > 0) {
            Deposit storage lastDeposit = LPDeposits[LPDeposits.length - 1];
            if (lastDeposit.phaseIndex == currentPhaseIndex) {
                withdrawableBalance = lastDeposit.amount;
            }
        }

        return withdrawableBalance;
    }

    function getTSHAREBalance(address _user) public view returns (uint256) {
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

    function getWithdrawableTSHAREBalance(address _user) external view returns (uint256) {
        if (_isCurrentPhaseOpen()) return getTSHAREBalance(_user);

        // if current phase is closed only deposists made in the current phase can be withdrawn
        uint256 withdrawableBalance = 0;
        Deposit[] storage TSHAREDeposits = TSHAREDepositsForUser[_user];
        if (TSHAREDeposits.length > 0) {
            Deposit storage lastDeposit = TSHAREDeposits[TSHAREDeposits.length - 1];
            if (lastDeposit.phaseIndex == currentPhaseIndex) {
                withdrawableBalance = lastDeposit.amount;
            }
        }

        return withdrawableBalance;
    }

    /*
    * USER DEPOSIT FUNCTIONS
    * user must have approved contract for the amounts prior to invoking!
    */

    function depositFTM() external payable {
        // convert to LP then call depositLP
    }

    function depositTOMB(uint256 _amount) external {
        // convert to LP then call depositLP
    }

    function depositLP(uint256 _amount) external {
        require(_amount > 0, "Cannot deposit 0 LP tokens!");
        require(spookyTombFtmLP.allowance(msg.sender, address(this)) >= _amount, "Don't have allowance for this amount!");
        spookyTombFtmLP.transferFrom(msg.sender, address(this), _amount);

        Deposit memory deposit = Deposit(_amount, currentPhaseIndex);
        LPDepositsForUser[msg.sender].push(deposit);
        _settleLPAccount(msg.sender);
    }

    function depositTSHARE(uint256 _amount) external {
        require(_amount > 0, "Cannot deposit 0 TSHAREs!");
        require(tshare.allowance(msg.sender, address(this)) >= _amount, "Don't have allowance for this amount!");
        tshare.transferFrom(msg.sender, address(this), _amount);

        Deposit memory deposit = Deposit(_amount, currentPhaseIndex);
        TSHAREDepositsForUser[msg.sender].push(deposit);
        _settleTSHAREAccount(msg.sender);
    }

    /*
    * USER WITHDRAW FUNCTIONS
    */

    function withdrawLP(uint256 _amount) external {
        // require withdrawableBalance >= _amount
        // call settleAccount
        // require lastElement's amount >= _amount
        // subtract and transfer
        // if last element's balance becomes 0, pop
    }

    function withdrawTSHARE() external {
        // require withdrawableBalance >= _amount
        // call settleAccount
        // require lastElement's amount >= _amount
        // subtract and transfer
        // if last element's balance becomes 0, pop
    }

    /*
    * OPERATOR FUNCTIONS TO RUN CRYPT
    */

    function lock() external onlyRole(OPERATOR_ROLE) {

    }

    function unlock() external onlyRole(OPERATOR_ROLE) {

    }

    /*
    * INTERNAL FUNCTIONS
    */

    /*
    * call right after depositing, or right before withdrawing
    *
    * _settleAccount function trims the deposits array to only 1 or 2 items.
    * it essentially moves all unrealized gains into a user's balance
    * and updates the phaseIndex to be current
    */
    function _settleLPAccount(address _user) internal {
        Deposit[] storage deposits = LPDepositsForUser[_user];
        if (deposits.length == 0) return; // early return for empty array

        if (_isCurrentPhaseOpen()) {
            if (deposits.length != 1 || deposits[0].phaseIndex != currentPhaseIndex) {
                deposits[0].amount = getLPBalance(_user);
                deposits[0].phaseIndex = currentPhaseIndex;

                // pop until array is length 1
                while(deposits.length > 1) deposits.pop();
            }
        } else { // current phase is closed, ONLY 3 cases possible
            if (deposits.length == 1 && deposits[0].phaseIndex == currentPhaseIndex) {
                // case 1: user only has one deposit in current phase, no-op
            } else if (deposits.length > 1 && deposits[deposits.length - 1].phaseIndex == currentPhaseIndex) {
                // case 2: user has multiple deposits and the last one is in current phase
                // in this case we need to leave the last deposit alone and consolidate the ones behind it
                deposits[0].amount = getLPBalance(_user) - deposits[deposits.length - 1].amount;
                deposits[0].phaseIndex = currentPhaseIndex - 1; // as if the user had deposited in the previous (open) phase

                // move latest deposit from current phase into index 1
                deposits[1].amount = deposits[deposits.length - 1].amount;
                deposits[1].phaseIndex = currentPhaseIndex;

                // pop until array is length 2
                while(deposits.length > 2) deposits.pop();
            } else {
                // case 3: user only has deposits (one or multiple) from before the current phase
                // in this case we just consolidate all of them with phaseIndex as (current - 1)
                deposits[0].amount = getLPBalance(_user);
                deposits[0].phaseIndex = currentPhaseIndex - 1;

                // pop until array is length 1
                while(deposits.length > 1) deposits.pop();
            }
        }
    }

    function _settleTSHAREAccount(address _user) internal {
        Deposit[] storage deposits = TSHAREDepositsForUser[_user];
        if (deposits.length == 0) return; // early return for empty array

        if (_isCurrentPhaseOpen()) {
            if (deposits.length != 1 || deposits[0].phaseIndex != currentPhaseIndex) {
                deposits[0].amount = getTSHAREBalance(_user);
                deposits[0].phaseIndex = currentPhaseIndex;

                // pop until array is length 1
                while(deposits.length > 1) deposits.pop();
            }
        } else { // current phase is closed, ONLY 3 cases possible
            if (deposits.length == 1 && deposits[0].phaseIndex == currentPhaseIndex) {
                // case 1: user only has one deposit in current phase, no-op
            } else if (deposits.length > 1 && deposits[deposits.length - 1].phaseIndex == currentPhaseIndex) {
                // case 2: user has multiple deposits and the last one is in current phase
                // in this case we need to leave the last deposit alone and consolidate the ones behind it
                deposits[0].amount = getTSHAREBalance(_user) - deposits[deposits.length - 1].amount;
                deposits[0].phaseIndex = currentPhaseIndex - 1; // as if the user had deposited in the previous (open) phase

                // move latest deposit from current phase into index 1
                deposits[1].amount = deposits[deposits.length - 1].amount;
                deposits[1].phaseIndex = currentPhaseIndex;

                // pop until array is length 2
                while(deposits.length > 2) deposits.pop();
            } else {
                // case 3: user only has deposits (one or multiple) from before the current phase
                // in this case we just consolidate all of them with phaseIndex as (current - 1)
                deposits[0].amount = getTSHAREBalance(_user);
                deposits[0].phaseIndex = currentPhaseIndex - 1;

                // pop until array is length 1
                while(deposits.length > 1) deposits.pop();
            }
        }
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
