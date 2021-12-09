// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TombVanillaCompounder.sol";

contract TombSoloCrypt is TombVanillaCompounder {
	constructor(
		address _tomb,
		address _tshare,
		address _spookyTombFtmLP,
		address _masonry,
		address _cemetery,
		address _spookyRouter
	) TombVanillaCompounder(
		_tomb,
		_tshare,
		_spookyTombFtmLP,
		_masonry,
		_cemetery,
		_spookyRouter
	) {	}

	// Deposit LPs into this contract, which then get deposited into Tomb's Cemetery
	// The caller must have approved this contract to spend the LPs beforehand
	function depositLP(uint256 _amount) external {
		require(spookyTombFtmLP.allowance(msg.sender, address(this)) >= _amount, "Don't have allowance for this amount!");
		spookyTombFtmLP.transferFrom(msg.sender, address(this), _amount);
		spookyTombFtmLP.approve(address(cemetery), _amount);
		cemetery.deposit(0, _amount);
	}

	// Run the vanilla Tomb routine
	function runRoutine() external {
		_claimAnyTSHARERewardsFromCemetery();
		_claimAnyTOMBRewardsFromMasonryIfAllowed();

		_depositAnyTSHAREIntoMasonry();

		_swapHalfTOMBForFTM();
		_addFTMTOMBLiquidity();
		_depositAnyLPIntoCemetery();
	}
}
