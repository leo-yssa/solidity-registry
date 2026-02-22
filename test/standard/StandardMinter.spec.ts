import { expect } from 'chai';
import { ethers } from 'hardhat';

import { buildMerkleTree, getProof } from '../utils/merkle';
import { latestTimestamp, setNextBlockTimestamp } from '../utils/time';

describe('StandardMinter', () => {
  it('mints presale with merkle proof and forwards funds', async () => {
    const [deployer, withdraw, alice] = await ethers.getSigners();

    const Standard = await ethers.getContractFactory('Standard', deployer);
    const nft = await Standard.deploy('Test', 'TST', 100, 'ipfs://base/');
    await nft.deployed();

    const StandardMinter = await ethers.getContractFactory('StandardMinter', deployer);
    const { tree } = buildMerkleTree([alice.address]);
    const minter = await StandardMinter.deploy(nft.address, withdraw.address, tree.getHexRoot());
    await minter.deployed();

    const MINTER_ROLE = await nft.MINTER_ROLE();
    await nft.grantRole(MINTER_ROLE, minter.address);

    const now = await latestTimestamp();
    await minter.setPreSaleValues(10, ethers.utils.parseEther('0.01'), now + 10, now + 1000, 50);
    await setNextBlockTimestamp(now + 20);

    const tokens = [{ tokenId: 1 }, { tokenId: 2 }];
    const proof = getProof(tree, alice.address);

    const before = await ethers.provider.getBalance(withdraw.address);
    await expect(
      minter.connect(alice).mintPreSale(tokens, proof, { value: ethers.utils.parseEther('0.02') })
    ).to.not.be.reverted;
    const after = await ethers.provider.getBalance(withdraw.address);

    expect(after.sub(before)).to.eq(ethers.utils.parseEther('0.02'));
    expect(await nft.totalSupply()).to.eq(2);
    expect(await nft.ownerOf(1)).to.eq(alice.address);
  });

  it('EOA policy is opt-in (default allows contract calls)', async () => {
    const [deployer, withdraw, alice] = await ethers.getSigners();

    const Standard = await ethers.getContractFactory('Standard', deployer);
    const nft = await Standard.deploy('Test', 'TST', 100, 'ipfs://base/');
    await nft.deployed();

    const StandardMinter = await ethers.getContractFactory('StandardMinter', deployer);
    const { tree } = buildMerkleTree([alice.address]);
    const minter = await StandardMinter.deploy(nft.address, withdraw.address, tree.getHexRoot());
    await minter.deployed();

    expect(await minter.enforceEOA()).to.eq(false);
  });
});

