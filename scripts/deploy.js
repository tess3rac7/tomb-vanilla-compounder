 const TombAddress = "0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7";
 const TShareAddress = "0x4cdF39285D7Ca8eB3f090fDA0C069ba5F4145B37";
 const SpookyTombFtmLPAddress = "0x2A651563C9d3Af67aE0388a5c8F89b867038089e";
 const MasonryAddress = "0x8764DE60236C5843D9faEB1B638fbCE962773B67";
 const CemeteryAddress = "0xcc0a87F7e7c693042a9Cc703661F5060c80ACb43";
 const SpookyRouterAddress = "0xF491e7B69E4244ad4002BC14e878a34207E38c29";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const factory = await ethers.getContractFactory("TombVanillaCompounder");
  const contract = await factory.deploy(
    TombAddress,
    TShareAddress,
    SpookyTombFtmLPAddress,
    MasonryAddress,
    CemeteryAddress,
    SpookyRouterAddress,
  );

  console.log("Contract address:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
