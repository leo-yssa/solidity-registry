import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';
import { ERC20UUPS } from '../lib/interfaces';

describe('ERC20UUPS', function () {
    it('Should deploy, initialize, and upgrade correctly', async function () {
        const [owner, otherAccount] = await ethers.getSigners();

        const UUPSFactory = await ethers.getContractFactory('ERC20UUPS');
        // Deploying UUPS proxy
        const proxy = (await upgrades.deployProxy(UUPSFactory, ['MyTokenUUPS', 'MTU', ethers.utils.parseEther('1000')], {
            kind: 'uups',
        })) as ERC20UUPS;
        await proxy.deployed();

        expect(await proxy.name()).to.equal('MyTokenUUPS');
        expect(await proxy.symbol()).to.equal('MTU');
        expect(await proxy.balanceOf(owner.address)).to.equal(ethers.utils.parseEther('1000'));

        // Mint test
        await proxy.mint(otherAccount.address, ethers.utils.parseEther('500'));
        expect(await proxy.balanceOf(otherAccount.address)).to.equal(ethers.utils.parseEther('500'));

        // Upgrading UUPS proxy (Upgrading to itself for testing)
        const upgradedProxy = await upgrades.upgradeProxy(proxy.address, UUPSFactory);
        expect(upgradedProxy.address).to.equal(proxy.address);
        expect(await upgradedProxy.name()).to.equal('MyTokenUUPS');
    });
});
