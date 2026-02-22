import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('StandardPresetFull', () => {
  it('supports tag assignment + admin burn + transfer limits', async () => {
    const [deployer, alice] = await ethers.getSigners();

    const StandardPresetFull = await ethers.getContractFactory('StandardPresetFull', deployer);
    const c = await StandardPresetFull.deploy('Abi', 'ABI', 100, 'ipfs://base/');
    await c.deployed();

    const MINTER_ROLE = await c.MINTER_ROLE();
    await c.grantRole(MINTER_ROLE, deployer.address);

    // mint token 1 to alice
    await c.mint(alice.address, 1);
    await c.assignTagToTokenId('', 1);

    // admin burn allowed and works
    await c.updateAdminBurnPermission(true);
    await expect(c.adminBurn([{ tokenId: 1, tokenOwner: alice.address }])).to.not.be.reverted;
    await expect(c.ownerOf(1)).to.be.reverted;
  });

  it('enforces transfer limit once configured', async () => {
    const [deployer, alice, bob, carol] = await ethers.getSigners();

    const StandardPresetFull = await ethers.getContractFactory('StandardPresetFull', deployer);
    const c = await StandardPresetFull.deploy('Abi', 'ABI', 100, 'ipfs://base/');
    await c.deployed();

    const MINTER_ROLE = await c.MINTER_ROLE();
    await c.grantRole(MINTER_ROLE, deployer.address);

    await c.mint(alice.address, 1);
    await c.assignTagToTokenId('', 1);

    // allow only 1 transfer
    await c.setTransferLimit(1);

    await c.connect(alice).transferFrom(alice.address, bob.address, 1);
    await expect(c.connect(bob).transferFrom(bob.address, carol.address, 1)).to.be.revertedWithCustomError(
      c,
      'TransferLimitExceeded'
    );
  });
});

