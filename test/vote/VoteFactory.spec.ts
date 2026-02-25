import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('VoteFactory + VoteExecutor', () => {
  it('factory creates Vote and executor executes payout', async () => {
    const [factoryOwner, executorOwner, voteOwner, voter] = await ethers.getSigners();

    const VoteFactory = await ethers.getContractFactory('VoteFactory', factoryOwner);
    const factory = await VoteFactory.deploy();
    await factory.waitForDeployment();

    const Hasher = await ethers.getContractFactory('MockHasher', executorOwner);
    const hasher = await Hasher.deploy();
    await hasher.waitForDeployment();

    const Verifier = await ethers.getContractFactory('MockVerifier', executorOwner);
    const verifier = await Verifier.deploy();
    await verifier.waitForDeployment();

    const VoteExecutor = await ethers.getContractFactory('VoteExecutor', executorOwner);
    const executor = await VoteExecutor.deploy(await factory.getAddress(), 2, await hasher.getAddress(), await verifier.getAddress());
    await executor.waitForDeployment();

    await factory.connect(factoryOwner).setExecutor(await executor.getAddress());

    const hash = 123;
    const totalReward = ethers.parseEther('1');
    const perReward = ethers.parseEther('0.1');

    await factory
      .connect(voteOwner)
      .create('vote-1', hash, totalReward, perReward, false, 0, false, false, [], [], [], [], [], {
        value: totalReward,
      });

    const voteAddr = await factory.getVoteAddress(hash);
    expect(voteAddr).to.not.eq(ethers.ZeroAddress);

    const before = await ethers.provider.getBalance(voter.address);
    await executor
      .connect(executorOwner)
      .execute(hash, voter.address, 999, [], [], [], [], [], [], [], []);
    const after = await ethers.provider.getBalance(voter.address);

    expect(after - before).to.eq(perReward);
  });
});

