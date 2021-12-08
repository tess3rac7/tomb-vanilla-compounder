const { Webhook } = require('discord-webhook-node');
const ethers = require('ethers');

const abi = require('./TombVanillaCompounder.json');

const address = "0x4d6e4da4E7c3484544ccA52cAf1f8b4A75fE4928";

const hook = new Webhook(process.env.DISCORD_WEBHOOK);

exports.handler = async function() {
	const provider = new ethers.providers.JsonRpcProvider("https://rpcapi.fantom.network", 250); // OPERA MAINNET CHAIN ID
	let wallet = new ethers.Wallet(process.env.RUNNER_PRIVATE_KEY, provider);

	const contract = new ethers.Contract(
		address,
		abi,
		wallet,
	)

	try {
		const tx = await contract.runRoutine();

		const successMessage = `:white_check_mark: Transaction sent https://ftmscan.com/tx/${tx.hash}`;
		await postToDiscord(successMessage);
	} catch (err) {
		const errorMessage = `:warning: Transaction failed: ${err.message}`;
		await postToDiscord(errorMessage);
		return err;
	}

	return true;
}

function postToDiscord(text) {
	hook.send(text);
}
