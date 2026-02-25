import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('Standard', () => {
  it('mints only with MINTER_ROLE and enforces maxSupply/URI offset logic', async () => {
    const [deployer, minter, alice] = await ethers.getSigners();

    const Standard = await ethers.getContractFactory('Standard', deployer);
    const nft = await Standard.deploy('Test', 'TST', 5, 'ipfs://base/');
    await nft.waitForDeployment();

    const MINTER_ROLE = await nft.MINTER_ROLE();
    await nft.grantRole(MINTER_ROLE, minter.address);

    await expect(nft.connect(alice).mint(alice.address, 1)).to.be.reverted;
    await expect(nft.connect(minter).mint(alice.address, 1)).to.not.be.reverted;

    expect(await nft.totalSupply()).to.eq(1);
    expect(await nft.tokenURI(1)).to.eq('ipfs://base/1.json');

    await nft.connect(minter).setTokenOffset(2);
    expect(await nft.tokenOffset()).to.eq(2);
    expect(await nft.tokenURI(1)).to.eq('ipfs://base/3.json');
  });
});

