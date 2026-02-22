import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('VoteFactory + VoteExecutor', () => {
  it('factory creates Vote and executor executes payout', async () => {
    const [factoryOwner, executorOwner, voteOwner, voter] = await ethers.getSigners();

    const VoteFactory = await ethers.getContractFactory('VoteFactory', factoryOwner);
    const factory = await VoteFactory.deploy();
    await factory.deployed();

    const Hasher = await ethers.getContractFactory('MockHasher', executorOwner);
    const hasher = await Hasher.deploy();
    await hasher.deployed();

    const Verifier = await ethers.getContractFactory('MockVerifier', executorOwner);
    const verifier = await Verifier.deploy();
    await verifier.deployed();

    const VoteExecutor = await ethers.getContractFactory('VoteExecutor', executorOwner);
    const executor = await VoteExecutor.deploy(factory.address, 2, hasher.address, verifier.address);
    await executor.deployed();

    await factory.connect(factoryOwner).setExecutor(executor.address);

    const hash = 123;
    const totalReward = ethers.utils.parseEther('1');
    const perReward = ethers.utils.parseEther('0.1');

    await factory
      .connect(voteOwner)
      .create('vote-1', hash, totalReward, perReward, false, 0, false, false, [], [], [], [], [], {
        value: totalReward,
      });

    const voteAddr = await factory.getVoteAddress(hash);
    expect(voteAddr).to.not.eq(ethers.constants.AddressZero);

    const before = await ethers.provider.getBalance(voter.address);
    await executor
      .connect(executorOwner)
      .execute(hash, voter.address, 999, [], [], [], [], [], [], [], []);
    const after = await ethers.provider.getBalance(voter.address);

    expect(after.sub(before)).to.eq(perReward);
  });
});

