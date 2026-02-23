import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';
import { ERC20Transparent } from '../lib/interfaces';

describe('ERC20Transparent', function () {
    it('Should deploy Transparent proxy, initialize, and upgrade correctly', async function () {
        const [owner, otherAccount] = await ethers.getSigners();

        const TransparentFactory = await ethers.getContractFactory('ERC20Transparent');
        // Deploying Transparent proxy
        const proxy = (await upgrades.deployProxy(TransparentFactory, ['MyTokenTransparent', 'MTT', ethers.utils.parseEther('1000')], {
            kind: 'transparent',
        })) as ERC20Transparent;
        await proxy.deployed();

        expect(await proxy.name()).to.equal('MyTokenTransparent');
        expect(await proxy.symbol()).to.equal('MTT');
        expect(await proxy.balanceOf(owner.address)).to.equal(ethers.utils.parseEther('1000'));

        // Mint test
        await proxy.mint(otherAccount.address, ethers.utils.parseEther('500'));
        expect(await proxy.balanceOf(otherAccount.address)).to.equal(ethers.utils.parseEther('500'));

        // Upgrading Transparent proxy
        const upgradedProxy = await upgrades.upgradeProxy(proxy.address, TransparentFactory);
        expect(upgradedProxy.address).to.equal(proxy.address);
        expect(await upgradedProxy.name()).to.equal('MyTokenTransparent');
    });
});
