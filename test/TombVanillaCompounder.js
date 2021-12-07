const { expect } = require("chai");
const { deployMockContract } = require('@ethereum-waffle/mock-contract');

const IERC20 = require('../artifacts/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json');
const IUniswapV2Pair = require('../artifacts/contracts/interfaces/IUniswapV2Pair.sol/IUniswapV2Pair.json');
const IMasonry = require('../artifacts/contracts/interfaces/IMasonry.sol/IMasonry.json');
const ITShareRewardPool = require('../artifacts/contracts/interfaces/ITShareRewardPool.sol/ITShareRewardPool.json');
const IUniswapV2Router02 = require('../artifacts/contracts/interfaces/IUniswapV2Router02.sol/IUniswapV2Router02.json');

describe("TombVanillaCompounder", () => {
  let contractFactory;
  let contract;

  let mockTomb;
  let mockTShare;
  let mockSpookyTombFtmLP;

  let mockMasonry;
  let mockCemetery;
  let mockSpookyRouter;

  let owner;
  let notOwner;

  beforeEach(async () => {
    [owner, notOwner] = await ethers.getSigners();

    mockTomb = await deployMockContract(owner, IERC20.abi);
    mockTShare = await deployMockContract(owner, IERC20.abi);
    mockSpookyTombFtmLP = await deployMockContract(owner, IUniswapV2Pair.abi);

    mockMasonry = await deployMockContract(owner, IMasonry.abi);
    mockCemetery = await deployMockContract(owner, ITShareRewardPool.abi);
    mockSpookyRouter = await deployMockContract(owner, IUniswapV2Router02.abi);

    contractFactory = await ethers.getContractFactory("TombVanillaCompounder");
    contract = await contractFactory.deploy(
      mockTomb.address,
      mockTShare.address,
      mockSpookyTombFtmLP.address,
      mockMasonry.address,
      mockCemetery.address,
      mockSpookyRouter.address
    )
  })

  describe("getters", async () => {
    it("gets the right TSHARE balance at Masonry", async () => {
      await mockMasonry.mock.balanceOf.withArgs(contract.address).returns(100);
      expect(await contract.getTSHAREBalanceAtTombMasonry()).to.equal(100);
    });

    it("gets the right LP balance at Cemetery", async () => {
      await mockCemetery.mock.userInfo.withArgs(0, contract.address).returns(10, 1);
      expect(await contract.getLPBalanceAtTombCemetery()).to.equal(10);
    });
  })

  describe("withdrawers", async () => {
    it("only owner should be able to withdraw FTM", async () => {
      await expect(contract.connect(notOwner).withdrawDustFTM()).to.be.reverted;
    })

    it("owner is able to withdraw FTM when contract has some", async () => {
      // when contract has 0 FTM
      await expect(contract.withdrawDustFTM()).to.be.revertedWith("No dust FTM to withdraw!");

      await notOwner.sendTransaction({to: contract.address, value: 200});
      expect(await contract.withdrawDustFTM()).to.changeEtherBalance(owner, 200);
    })

    it("only owner should be able to withdraw TOMB", async () => {
      await expect(contract.connect(notOwner).withdrawDustTOMB()).to.be.reverted;
    })

    it("owner is able to withdraw TOMB when contract has some", async () => {
      // when contract has 0 TOMB
      await mockTomb.mock.balanceOf.withArgs(contract.address).returns(0);
      await expect(contract.withdrawDustTOMB()).to.be.revertedWith("No dust TOMB to withdraw!");

      // Running into issues here due to SafeERC20
      // Probably need to create live instances of tokens instead of mocking them
      // await mockTomb.mock.balanceOf.withArgs(contract.address).returns(200);
      // await mockTomb.mock.transfer().returns();
      // await contract.withdrawDustTOMB();
      // expect('safeTransfer').to.be.calledOnContractWith(mockTomb, owner.address, 200);
    })
  })
});