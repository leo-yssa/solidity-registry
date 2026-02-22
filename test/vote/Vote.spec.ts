import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('Vote', () => {
  it('only controller can execute/complete and execute pays perReward', async () => {
    const [controller, owner, alice] = await ethers.getSigners();

    const totalReward = ethers.utils.parseEther('1');
    const perReward = ethers.utils.parseEther('0.1');

    const Vote = await ethers.getContractFactory('Vote', controller);
    const vote = await Vote.deploy(
      controller.address,
      owner.address,
      'vote-1',
      totalReward,
      perReward,
      false, // zkp
      0, // totalSupply
      false, // targeting
      false, // condition
      [],
      [],
      [],
      [],
      [],
      { value: totalReward }
    );
    await vote.deployed();

    await expect(vote.connect(alice).execute(alice.address, 123)).to.be.revertedWith('caller is not controller');

    const beforeAlice = await ethers.provider.getBalance(alice.address);
    await vote.connect(controller).execute(alice.address, 123);
    const afterAlice = await ethers.provider.getBalance(alice.address);

    expect(afterAlice.sub(beforeAlice)).to.eq(perReward);

    const info = await vote.connect(controller).get();
    expect(info.count).to.eq(1);
    expect(info.paiedReward).to.eq(perReward);

    const beforeOwner = await ethers.provider.getBalance(owner.address);
    await vote.connect(controller).complete(owner.address);
    const afterOwner = await ethers.provider.getBalance(owner.address);

    expect(afterOwner.sub(beforeOwner)).to.eq(totalReward.sub(perReward));
  });
});

