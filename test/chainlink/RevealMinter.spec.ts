import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('RevealMinter / ARevealer', () => {
  it('marks token as roll-in-progress then sets asset index on fulfill', async () => {
    const [deployer, withdraw, alice] = await ethers.getSigners();

    const MockCoord = await ethers.getContractFactory('MockVRFCoordinatorV2', deployer);
    const coord = await MockCoord.deploy();
    await coord.waitForDeployment();

    const NFT = await ethers.getContractFactory('ChainlinkPresetMinimal', deployer);
    const nft = await NFT.deploy('CL', 'CL', 10, 'ipfs://base/');
    await nft.waitForDeployment();

    const RevealMinter = await ethers.getContractFactory('RevealMinter', deployer);
    const merkleRoot = ethers.ZeroHash;
    const keyHash = ethers.ZeroHash;
    const minter = await RevealMinter.deploy(
      await nft.getAddress(),
      1, // subId
      await coord.getAddress(),
      keyHash,
      10, // totalSupply
      withdraw.address,
      merkleRoot
    );
    await minter.waitForDeployment();

    const MINTER_ROLE = await nft.MINTER_ROLE();
    await nft.grantRole(MINTER_ROLE, await minter.getAddress());

    // prepare available asset indices
    await minter.setAssetIndexArray(10);
    expect(await minter.getAssetIndexArraySize()).to.eq(10);

    const tx = await minter.mappedAirdrop([{ receiver: alice.address, tokenId: 1 }]);
    const rc = await tx.wait();
    if (!rc) throw new Error('no receipt');
    const topic = minter.interface.getEvent('RandomRolled').topicHash;
    const log = rc.logs.find((l) => l.topics[0] === topic);
    expect(log, 'RandomRolled not found').to.not.be.undefined;
    const parsed = minter.interface.parseLog({ topics: log!.topics as string[], data: log!.data });
    const requestId = parsed!.args[0];

    // roll-in-progress set on both minter and nft
    const ROLL = await minter._ROLL_IN_PROGRESS();
    expect(await minter.tokenIdToAssetIndex(1)).to.eq(ROLL);
    expect(await nft.tokenIdToAssetIndex(1)).to.eq(ROLL);

    // fulfill VRF
    await coord.fulfill(await minter.getAddress(), requestId, [7]);
    const idx = await minter.tokenIdToAssetIndex(1);
    expect(idx).to.not.eq(ROLL);
    expect(await nft.tokenIdToAssetIndex(1)).to.eq(idx);
    expect(await minter.getAssetIndexArraySize()).to.eq(9);
  });

  it('tokenRevealByOwner is onlyOwner', async () => {
    const [deployer, withdraw, alice] = await ethers.getSigners();

    const MockCoord = await ethers.getContractFactory('MockVRFCoordinatorV2', deployer);
    const coord = await MockCoord.deploy();
    await coord.waitForDeployment();

    const NFT = await ethers.getContractFactory('ChainlinkPresetMinimal', deployer);
    const nft = await NFT.deploy('CL', 'CL', 10, 'ipfs://base/');
    await nft.waitForDeployment();

    const RevealMinter = await ethers.getContractFactory('RevealMinter', deployer);
    const minter = await RevealMinter.deploy(
      await nft.getAddress(),
      1,
      await coord.getAddress(),
      ethers.ZeroHash,
      10,
      withdraw.address,
      ethers.ZeroHash
    );
    await minter.waitForDeployment();

    await expect(minter.connect(alice).tokenRevealByOwner(1)).to.be.revertedWith('Ownable: caller is not the owner');
  });
});

