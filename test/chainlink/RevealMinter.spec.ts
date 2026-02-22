import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('RevealMinter / ARevealer', () => {
  it('marks token as roll-in-progress then sets asset index on fulfill', async () => {
    const [deployer, withdraw, alice] = await ethers.getSigners();

    const MockCoord = await ethers.getContractFactory('MockVRFCoordinatorV2', deployer);
    const coord = await MockCoord.deploy();
    await coord.deployed();

    const NFT = await ethers.getContractFactory('ChainlinkPresetMinimal', deployer);
    const nft = await NFT.deploy('CL', 'CL', 10, 'ipfs://base/');
    await nft.deployed();

    const RevealMinter = await ethers.getContractFactory('RevealMinter', deployer);
    const merkleRoot = ethers.constants.HashZero;
    const keyHash = ethers.constants.HashZero;
    const minter = await RevealMinter.deploy(
      nft.address,
      1, // subId
      coord.address,
      keyHash,
      10, // totalSupply
      withdraw.address,
      merkleRoot
    );
    await minter.deployed();

    const MINTER_ROLE = await nft.MINTER_ROLE();
    await nft.grantRole(MINTER_ROLE, minter.address);

    // prepare available asset indices
    await minter.setAssetIndexArray(10);
    expect(await minter.getAssetIndexArraySize()).to.eq(10);

    const tx = await minter.mappedAirdrop([{ receiver: alice.address, tokenId: 1 }]);
    const rc = await tx.wait();

    const rolled = rc.events?.find((e) => e.event === 'RandomRolled');
    expect(rolled, 'RandomRolled not found').to.not.be.undefined;
    const requestId = rolled!.args!.requestId;

    // roll-in-progress set on both minter and nft
    const ROLL = await minter._ROLL_IN_PROGRESS();
    expect(await minter.tokenIdToAssetIndex(1)).to.eq(ROLL);
    expect(await nft.tokenIdToAssetIndex(1)).to.eq(ROLL);

    // fulfill VRF
    await coord.fulfill(minter.address, requestId, [7]);
    const idx = await minter.tokenIdToAssetIndex(1);
    expect(idx).to.not.eq(ROLL);
    expect(await nft.tokenIdToAssetIndex(1)).to.eq(idx);
    expect(await minter.getAssetIndexArraySize()).to.eq(9);
  });

  it('tokenRevealByOwner is onlyOwner', async () => {
    const [deployer, withdraw, alice] = await ethers.getSigners();

    const MockCoord = await ethers.getContractFactory('MockVRFCoordinatorV2', deployer);
    const coord = await MockCoord.deploy();
    await coord.deployed();

    const NFT = await ethers.getContractFactory('ChainlinkPresetMinimal', deployer);
    const nft = await NFT.deploy('CL', 'CL', 10, 'ipfs://base/');
    await nft.deployed();

    const RevealMinter = await ethers.getContractFactory('RevealMinter', deployer);
    const minter = await RevealMinter.deploy(
      nft.address,
      1,
      coord.address,
      ethers.constants.HashZero,
      10,
      withdraw.address,
      ethers.constants.HashZero
    );
    await minter.deployed();

    await expect(minter.connect(alice).tokenRevealByOwner(1)).to.be.revertedWith('Ownable: caller is not the owner');
  });
});

