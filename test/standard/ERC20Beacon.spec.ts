import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';
import type { ERC20Beacon } from '../../lib/interfaces';

describe('ERC20Beacon', function () {
    it('Should deploy Beacon, deploy proxy, and upgrade correctly', async function () {
        const [owner, otherAccount] = await ethers.getSigners();

        const BeaconFactory = await ethers.getContractFactory('ERC20Beacon');

        // Deploying the Beacon
        const beacon = await upgrades.deployBeacon(BeaconFactory);
        await beacon.waitForDeployment();

        // Deploying the Beacon Proxy
        const proxy = (await upgrades.deployBeaconProxy(beacon, BeaconFactory, ['MyTokenBeacon', 'MTB', ethers.parseEther('1000')])) as ERC20Beacon;
        await proxy.waitForDeployment();

        expect(await proxy.name()).to.equal('MyTokenBeacon');
        expect(await proxy.symbol()).to.equal('MTB');
        expect(await proxy.balanceOf(owner.address)).to.equal(ethers.parseEther('1000'));

        // Mint test
        await proxy.mint(otherAccount.address, ethers.parseEther('500'));
        expect(await proxy.balanceOf(otherAccount.address)).to.equal(ethers.parseEther('500'));

        // Upgrading the Beacon
        const upgradedBeacon = await upgrades.upgradeBeacon(await beacon.getAddress(), BeaconFactory);
        expect(await upgradedBeacon.getAddress()).to.equal(await beacon.getAddress());
        expect(await proxy.name()).to.equal('MyTokenBeacon');
    });
});
