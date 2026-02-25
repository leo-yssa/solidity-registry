import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('NFTCreator (HTS)', () => {
  it('is owner-gated (local EVM cannot execute Hedera precompile calls)', async () => {
    const [deployer, other] = await ethers.getSigners();

    const Creator = await ethers.getContractFactory('NFTCreator', deployer);
    const c = await Creator.deploy();
    await c.waitForDeployment();

    await expect(
      c.connect(other).create('N', 'S', 'memo', 100, 60)
    ).to.be.revertedWith('Ownable: caller is not the owner');

    await expect(c.connect(other).mint(ethers.ZeroAddress, [])).to.be.revertedWith(
      'Ownable: caller is not the owner'
    );
  });
});

